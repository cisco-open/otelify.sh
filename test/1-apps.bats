#!/usr/bin/env bats
# shellcheck disable=SC2317
#
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

_mock_setup() {
	node() {
		echo "OTEL_LOG_LEVEL=${OTEL_LOG_LEVEL}"
		echo "OTEL_TRACES_EXPORTER=${OTEL_TRACES_EXPORTER}"
		echo "OTEL_METRICS_EXPORTER=${OTEL_METRICS_EXPORTER}"
		echo "OTEL_LOGS_EXPORTER=${OTEL_LOGS_EXPORTER}"
		echo "NODE_PATH=${NODE_PATH}"
		echo "NODE_OPTIONS=${NODE_OPTIONS}"
		echo "node ${*}"
	}
	npm() {
		echo "npm ${*}"
	}
	java() {
		echo "OTEL_JAVAAGENT_DEBUG=${OTEL_JAVAAGENT_DEBUG}"
		echo "OTEL_TRACES_EXPORTER=${OTEL_TRACES_EXPORTER}"
		echo "OTEL_METRICS_EXPORTER=${OTEL_METRICS_EXPORTER}"
		echo "OTEL_LOGS_EXPORTER=${OTEL_LOGS_EXPORTER}"
		echo "OTEL_METRIC_EXPORT_INTERVAL=${OTEL_METRIC_EXPORT_INTERVAL}"
		echo "JAVA_TOOL_OPTIONS=${JAVA_TOOL_OPTIONS}"
		echo "java ${*}"
	}

	dotnet_instrument() {
		echo "OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED=${OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED}"
		echo "OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED=${OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED}"
		echo "OTEL_DOTNET_AUTO_LOGS_CONSOLE_EXPORTER_ENABLED=${OTEL_DOTNET_AUTO_LOGS_CONSOLE_EXPORTER_ENABLED}"
		echo "OTEL_TRACES_EXPORTER=${OTEL_TRACES_EXPORTER}"
		echo "OTEL_METRICS_EXPORTER=${OTEL_METRICS_EXPORTER}"
		echo "OTEL_LOGS_EXPORTER=${OTEL_LOGS_EXPORTER}"
		echo "${OTEL_DOTNET_AUTO_HOME}/instrument.sh ${*}"
	}

	enable_otel_debug_mode() {
		echo "export OTEL_JAVAAGENT_DEBUG=true"
		echo "export OTEL_LOG_LEVEL=debug"
	}

	chmod() {
		echo "chmod ${*}"	
	}

	dotnet_auto_install() {
		echo "${@}"
	}

	curl() {
		echo "curl ${*}"
	}

	export -f node
	export -f npm
	export -f java
	export -f dotnet_instrument
	export -f chmod
	export -f dotnet_auto_install
	export -f curl
}

setup() {
    load 'test_helper/common-setup'
    _mock_setup
    _common_setup
    APPJS=/tmp/app.js
    APPJAR=/tmp/myapp.jar
    echo 'console.log("test");' > "${APPJS}"
    touch "${APPJAR}"
}

teardown() {
    _common_teardown
    rm -f "${APPJS}" "${APPJAR}"
}

@test "can otelify nodejs applications" {

    run otelify.sh -- "${APPJS}"
    assert_output -  << END
npm install --prefix ${OTELIFY_DIRECTORY} @opentelemetry/auto-instrumentations-node @opentelemetry/api
OTEL_LOG_LEVEL=
OTEL_TRACES_EXPORTER=console
OTEL_METRICS_EXPORTER=console
OTEL_LOGS_EXPORTER=console
NODE_PATH=${OTELIFY_DIRECTORY}/node_modules:
NODE_OPTIONS= --require @opentelemetry/auto-instrumentations-node/register
node ${APPJS}
END

    run otelify.sh -- node -r ./mytest.js "${APPJS}"
    assert_output -  << END
npm install --prefix ${OTELIFY_DIRECTORY} @opentelemetry/auto-instrumentations-node @opentelemetry/api
OTEL_LOG_LEVEL=
OTEL_TRACES_EXPORTER=console
OTEL_METRICS_EXPORTER=console
OTEL_LOGS_EXPORTER=console
NODE_PATH=${OTELIFY_DIRECTORY}/node_modules:
NODE_OPTIONS= --require @opentelemetry/auto-instrumentations-node/register
node -r ./mytest.js ${APPJS}
END
}

@test "can otelify java applications" {
    run otelify.sh -- java -jar "${APPJAR}"
    assert_output -  << END
curl -o ${OTELIFY_DIRECTORY}/otelify-opentelemetry-javaagent.jar -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
OTEL_JAVAAGENT_DEBUG=
OTEL_TRACES_EXPORTER=logging
OTEL_METRICS_EXPORTER=logging
OTEL_LOGS_EXPORTER=logging
OTEL_METRIC_EXPORT_INTERVAL=15000
JAVA_TOOL_OPTIONS= -javaagent:${OTELIFY_DIRECTORY}/otelify-opentelemetry-javaagent.jar
java -jar ${APPJAR}
END

    run otelify.sh -- java -jar "${APPJAR}"
    assert_output -  << END
curl -o ${OTELIFY_DIRECTORY}/otelify-opentelemetry-javaagent.jar -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
OTEL_JAVAAGENT_DEBUG=
OTEL_TRACES_EXPORTER=logging
OTEL_METRICS_EXPORTER=logging
OTEL_LOGS_EXPORTER=logging
OTEL_METRIC_EXPORT_INTERVAL=15000
JAVA_TOOL_OPTIONS= -javaagent:${OTELIFY_DIRECTORY}/otelify-opentelemetry-javaagent.jar
java -jar ${APPJAR}
END
}

@test "can otelify .NET applications" {
    run otelify.sh -- dotnet run
    assert_output -  << END
curl -o /tmp/otelify-test-dir/otel-dotnet-auto-install.sh -L https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/latest/download/otel-dotnet-auto-install.sh
chmod +x /tmp/otelify-test-dir/otel-dotnet-auto-install.sh
/tmp/otelify-test-dir/otel-dotnet-auto-install.sh
chmod +x /tmp/otelify-test-dir/otel-dotnet-auto/instrument.sh
OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED=true
OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED=true
OTEL_DOTNET_AUTO_LOGS_CONSOLE_EXPORTER_ENABLED=true
OTEL_TRACES_EXPORTER=console
OTEL_METRICS_EXPORTER=console
OTEL_LOGS_EXPORTER=console
/tmp/otelify-test-dir/otel-dotnet-auto/instrument.sh dotnet run
END
}


@test "will run any command provided" {
    run otelify.sh -- echo "hello"
    assert_output - << END
curl -o /tmp/otelify-test-dir/otel-dotnet-auto-install.sh -L https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/latest/download/otel-dotnet-auto-install.sh
chmod +x /tmp/otelify-test-dir/otel-dotnet-auto-install.sh
/tmp/otelify-test-dir/otel-dotnet-auto-install.sh
chmod +x /tmp/otelify-test-dir/otel-dotnet-auto/instrument.sh
curl -o /tmp/otelify-test-dir/otelify-opentelemetry-javaagent.jar -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
npm install --prefix /tmp/otelify-test-dir @opentelemetry/auto-instrumentations-node @opentelemetry/api
OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED=true
OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED=true
OTEL_DOTNET_AUTO_LOGS_CONSOLE_EXPORTER_ENABLED=true
OTEL_TRACES_EXPORTER=console
OTEL_METRICS_EXPORTER=console
OTEL_LOGS_EXPORTER=console
/tmp/otelify-test-dir/otel-dotnet-auto/instrument.sh echo hello
END
}

@test "will set environment variables for otel debug mode" {
	run otelify.sh -D -- java -jar "${APPJAR}"
	assert_output - << END
curl -o ${OTELIFY_DIRECTORY}/otelify-opentelemetry-javaagent.jar -L https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
OTEL_JAVAAGENT_DEBUG=true
OTEL_TRACES_EXPORTER=logging
OTEL_METRICS_EXPORTER=logging
OTEL_LOGS_EXPORTER=logging
OTEL_METRIC_EXPORT_INTERVAL=15000
JAVA_TOOL_OPTIONS= -javaagent:${OTELIFY_DIRECTORY}/otelify-opentelemetry-javaagent.jar
java -jar ${APPJAR}
END

	run otelify.sh -D -- node -r ./mytest.js "${APPJS}"
	assert_output - << END
npm install --prefix ${OTELIFY_DIRECTORY} @opentelemetry/auto-instrumentations-node @opentelemetry/api
OTEL_LOG_LEVEL=debug
OTEL_TRACES_EXPORTER=console
OTEL_METRICS_EXPORTER=console
OTEL_LOGS_EXPORTER=console
NODE_PATH=${OTELIFY_DIRECTORY}/node_modules:
NODE_OPTIONS= --require @opentelemetry/auto-instrumentations-node/register
node -r ./mytest.js ${APPJS}
END
}