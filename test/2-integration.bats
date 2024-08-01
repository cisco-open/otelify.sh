#!/usr/bin/env bats
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

setup_file() {
    if [ "${WITH_INTEGRATION}" -eq "0" ]; then
        skip "Integration tests turned off: WITH_INTEGRATION=${WITH_INTEGRATION}"
    fi
    commands=("node" "npm" "java" "dotnet" "curl")
    for ((i = 0; i < ${#commands[@]}; i++)); do
        local command=${commands[$i]}
        if ! command -v "${command}" >/dev/null 2>&1; then
           skip "\"${command}\" is not available."
        fi
    done
    export URL="${INTEGRATION_TEST_URL}"
}

teardown_file() {
    if [ "${WITH_INTEGRATION}" -eq "0" ]; then
        skip "Integration tests turned off: WITH_INTEGRATION=${WITH_INTEGRATION}"
    fi
}

setup() {
    load 'test_helper/common-setup'
    _common_setup
    APP_DIR=./samples
}

teardown() {
    _common_teardown
    # rm -rf ${APP_DIR}
}

#bats test_tags=integration:nodejs, nodejs
@test "can otelify nodejs applications" {    
    run otelify.sh -- node "${APP_DIR}/app.js"
    assert_output --partial 'traceId: '
}

#bats test_tags=integration:nodejs-debug, nodejs, debug
@test "can otelify nodejs applications with debug mode enabled" {    
    run otelify.sh -D -- node "${APP_DIR}/app.js"
    assert_output --partial '@opentelemetry/api: Registered a global for diag'
}

#bats test_tags=integration:java, java
@test "can otelify java applications" {
    OLD_PWD=${PWD}
    cd "${APP_DIR}"
    javac App.java
    jar cvfm app.jar manifest.txt App.class
    cd "${OLD_PWD}"
    run otelify.sh -d -- java -jar "${APP_DIR}/app.jar"
    assert_output --partial 'io.opentelemetry.exporter.logging.LoggingSpanExporter'
}

#bats test_tags=integration:dotnet, dotnet
@test "can otelify dotnet applications" {
    run otelify.sh -d --  dotnet run --project "${APP_DIR}"
    assert_output --partial 'Activity.TraceId:'
}