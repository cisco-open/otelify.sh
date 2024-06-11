#!/usr/bin/env bash
# Copyright 2024 Cisco Systems, Inc. and its affiliates
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

# Set the default values
OTELIFY_STRICT=${OTELIFY_STRICT:-false}
OTELIFY_DEBUG=${OTELIFY_DEBUG:-false}
OTELIFY_KEEP_DOWNLOADS=${OTELIFY_KEEP_DOWNLOADS:-true}
OTELIFY_DIRECTORY=${OTELIFY_DIRECTORY:-~/.otelify}

#
OTEL_DOTNET_AUTO_INSTRUMENTATION_URL=https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/latest/download/otel-dotnet-auto-install.sh
OTEL_JAVA_AGENT_URL=https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
OTEL_NODEJS_PACKAGES="@opentelemetry/auto-instrumentations-node @opentelemetry/api"

# Some variables used across different auto instrumentations
# OTEL_DOTNET_AUTO_HOME needs to be exported, because it will be used in shell scripts
export OTEL_DOTNET_AUTO_HOME="${OTELIFY_DIRECTORY}/otel-dotnet-auto"
JAVA_AGENT_PATH=${OTELIFY_DIRECTORY}/otelify-opentelemetry-javaagent.jar
OTEL_DOTNET_AUTO_INSTALL="${OTELIFY_DIRECTORY}/otel-dotnet-auto-install.sh"

# usage function
usage() {
	echo "Usage: $0 [options] <application>"
	echo ""
	echo "Options:"
	echo "  -d: Enable debug mode"
	echo "  -e: Set the OpenTelemetry exporter for all signals, e.g. -e otlp"
	echo "  -f: Set the directory where the OpenTelemetry files will be downloaded, e.g. -f /tmp. Default is ~/.otelify"
	echo "  -h: Show this help message"
	echo "  -r: Remove the downloads after the script finishes"
	echo "  -s: Do not run the command if the language is not recognized"
	echo "  --: End of options"
	echo ""
	echo "Environment Variables:"
	echo "  OTELIFY_DIRECTORY: Set the directory where the OpenTelemetry files will be downloaded, e.g. /tmp. Default is ~/.otelify"
	echo "  OTELIFY_STRICT: If set to true, otelify will not run the command if the language is not recognized. Default is false"
	echo "  OTELIFY_DEBUG: If set to true, debug mode is enabled. Default is false"
	echo "  OTELIFY_KEEP_DOWNLOADS: If set to true, downloads will be removed after the script finishes. Default is true"
	echo ""
	echo "  All environment variables that start with OTEL_ will be passed to the OpenTelemetry SDK Configuration."
	echo "  OTEL_TRACES_EXPORTER, OTEL_METRICS_EXPORTER, OTEL_LOGS_EXPORTER are set to console by default."
	echo "  OTEL_METRIC_EXPORT_INTERVAL is set to 15000 by default."
}

# debug function
debug() {
	if [ "${OTELIFY_DEBUG}" = true ]; then
		echo "DEBUG: $1"
	fi
}

download_node() {
	# Download the OpenTelemetry Node.js auto-instrumentation package
	debug "Downloading the OpenTelemetry Node.js auto-instrumentation package"

	# Download node modules if they do not exist
	if [ ! -d "${OTELIFY_DIRECTORY}/node_modules" ]; then
		# shellcheck disable=SC2086
		npm install --prefix "${OTELIFY_DIRECTORY}" ${OTEL_NODEJS_PACKAGES}
	fi
	# only keep the downloads if the -k option is passed
	if [ "${OTELIFY_KEEP_DOWNLOADS}" = false ]; then
		trap 'rm -rf ${OTELIFY_DIRECTORY}/node_modules' EXIT
	fi
}

download_java() {
	# Download the agent if it does not exist
	if [ ! -f "${JAVA_AGENT_PATH}" ]; then
		debug "Downloading the OpenTelemetry Java agent"
		curl -o "${JAVA_AGENT_PATH}" -L ${OTEL_JAVA_AGENT_URL}
	fi
	# only keep the downloads if the -k option is passed
	if [ "${OTELIFY_KEEP_DOWNLOADS}" = false ]; then
		trap 'rm ${JAVA_AGENT_PATH}' EXIT
	fi
}

download_dotnet() {

	mkdir -p "${OTELIFY_DIRECTORY}/otel-dotnet-auto"

	# Download the OpenTelemetry .NET auto-instrumentation package if it does not exist
	if [ ! -f "${OTEL_DOTNET_AUTO_INSTALL}" ]; then
		curl -o "${OTEL_DOTNET_AUTO_INSTALL}" -L ${OTEL_DOTNET_AUTO_INSTRUMENTATION_URL}
		chmod +x "${OTEL_DOTNET_AUTO_INSTALL}"
		# only keep the downloads if the -k option is passed
		if [ "${OTELIFY_KEEP_DOWNLOADS}" = false ]; then
			trap 'rm -rf ${OTEL_DOTNET_AUTO_HOME}' EXIT
			trap 'rm ${OTEL_DOTNET_AUTO_INSTALL}' EXIT
		fi
		# shellcheck disable=SC2086
		dotnet_auto_install ${OTEL_DOTNET_AUTO_INSTALL}
		chmod +x "${OTEL_DOTNET_AUTO_HOME}/instrument.sh"
	fi
}

setup_java() {
	export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS} -javaagent:${JAVA_AGENT_PATH}"
}

setup_node() {
	export NODE_PATH="${OTELIFY_DIRECTORY}/node_modules:${NODE_PATH}"
	export NODE_OPTIONS="${NODE_OPTIONS} --require @opentelemetry/auto-instrumentations-node/register"
}

# allow tests to overwrite the following two functions for mocking
if [[ $(type -t dotnet_instrument) != function ]]; then
	dotnet_instrument() {
		# shellcheck disable=SC2068
		"${OTEL_DOTNET_AUTO_HOME}/instrument.sh" ${@}
	}
fi

if [[ $(type -t dotnet_auto_install) != function ]]; then
	dotnet_auto_install() {
		# shellcheck disable=SC2068
		${@}
	}
fi

# there should be at least one argument
if [ $# -lt 1 ]; then
	usage
	exit 0
fi

while getopts "de:f:hrs-:" opt; do
	case "${opt}" in
	'd')
		# if the option is -d, then debug mode is enabled
		OTELIFY_DEBUG=true
		debug "Debug mode enabled"
		;;
	'e')
		# if the option is -e, then the OpenTelemetry exporter is set for all signals
		debug "Setting the OpenTelemetry exporter for all signals to ${OPTARG}"
		OTEL_TRACES_EXPORTER=${OPTARG}
		OTEL_METRICS_EXPORTER=${OPTARG}
		OTEL_LOGS_EXPORTER=${OPTARG}
		;;
	'r')
		# if the option is -k, then downloads will be removed after the script finishes
		debug "Downloads will be removed after the script finishes"
		OTELIFY_KEEP_DOWNLOADS=false
		;;
	'-')
		# if the option is --, then the options are finished
		break
		;;
	'f')
		# if the option is -f, then files are downloaded to the specified directory
		debug Setting OTELIFY_DIRECTORY to "${OPTARG}"
		OTELIFY_DIRECTORY="${OPTARG}"
		;;
	'h')
		# if the option is -h, then the usage function is called
		usage
		exit 0
		;;
	's')
		# if the option is -s, then otelify will not run the command if the language is not recognized
		debug "Setting OTELIFY_STRICT to true"
		OTELIFY_STRICT=true
		;;
	\?)
		usage
		exit 1
		;;
	esac
done

# shift is used to remove the options from the arguments list
shift $((OPTIND - 1))

# check if OTELIFY_DIRECTORY exists, if not, create it
if [ ! -d "${OTELIFY_DIRECTORY}" ]; then
	debug "Creating OTELIFY_DIRECTORY at ${OTELIFY_DIRECTORY}"
	mkdir -p "${OTELIFY_DIRECTORY}"
fi

# remaining arguments are the application
application="${*}"

# $1 is the language
language="${1}"

# check if $language is a file
if [ -f "${language}" ]; then
	# check if file is a jar
	if [[ "${language}" == *".jar" ]]; then
		language="java"
		application="java -jar ${application}"
		debug "Java application detected"
	fi
	# check if file is a node.js application
	if [[ "${language}" == *".js" ]]; then
		language="node"
		application="node ${application}"
		debug "Node.js application detected"
	fi
	# check if the file is a .NET application
	if [[ "${language}" == *".dll" ]]; then
		language="dotnet"
		application="dotnet ${application}"
		debug ".NET application detected"
	fi
fi

# the "language" may be a path like /usr/bin/java, so we apply basename to strip the directory
language=$(basename "${language}")

debug "Application: ${application}, Language: ${language}"

# Setting up some common OpenTelemetry SDK Configuration Variables
export OTEL_TRACES_EXPORTER=${OTEL_TRACES_EXPORTER:-console}
export OTEL_METRICS_EXPORTER=${OTEL_METRICS_EXPORTER:-console}
export OTEL_LOGS_EXPORTER=${OTEL_LOGS_EXPORTER:-console}
export OTEL_METRIC_EXPORT_INTERVAL=${OTEL_METRIC_EXPORT_INTERVAL:-15000}
# .NET Auto Instrumentation needs some extra treatment for the console exporter
if [ "${OTEL_TRACES_EXPORTER}" = "console" ]; then
	export OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED=true
fi
if [ "${OTEL_METRICS_EXPORTER}" = "console" ]; then
	export OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED=true
fi
if [ "${OTEL_LOGS_EXPORTER}" = "console" ]; then
	export OTEL_DOTNET_AUTO_LOGS_CONSOLE_EXPORTER_ENABLED=true
fi

case "${language}" in
"dotnet")
	download_dotnet

	debug "Starting the application with the OpenTelemetry .NET"

	# shellcheck disable=SC2086
	dotnet_instrument ${application}

	;;
"java")
	download_java

	debug "Starting the application with the OpenTelemetry Java"

	setup_java

	# Java currently does not support "console", but "logging"
	if [ "${OTEL_TRACES_EXPORTER}" = "console" ]; then
		export OTEL_TRACES_EXPORTER="logging"
	fi
	if [ "${OTEL_METRICS_EXPORTER}" = "console" ]; then
		export OTEL_METRICS_EXPORTER="logging"
	fi
	if [ "${OTEL_LOGS_EXPORTER}" = "console" ]; then
		export OTEL_LOGS_EXPORTER="logging"
	fi

	${application}

	;;
"node")
	download_node

	debug "Starting the application with the OpenTelemetry Node.js"

	setup_node

	${application}

	;;
*)
	debug "Unknown language"
	if [ "${OTELIFY_STRICT}" = true ]; then
		echo "Will not run the command in strict mode because the language is not recognized"
		exit 1
	fi

	# If no language is detected and we are not in strict mode, we apply ALL potential instrumentations, hoping that one works
	download_dotnet
	download_java
	download_node

	setup_java
	setup_node

	debug "Starting the application with OpenTelemetry"

	# shellcheck disable=SC2086
	dotnet_instrument ${application}
	;;
esac
