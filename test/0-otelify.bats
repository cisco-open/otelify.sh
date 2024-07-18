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

setup() {
    load 'test_helper/common-setup'
    _common_setup
}

teardown() {
    _common_teardown
}

get_usage_line() {
    otelify.sh 2>&1 | grep Usage
}

@test "can run otelify.sh" {
    run get_usage_line
    assert_output "Usage: ${OTELIFY_SHELL_SCRIPT_PATH}/otelify.sh [options] <application>"
}

get_debug_line() {
    otelify.sh -d -- echo "hello" 2>&1 | grep "DEBUG: Unknown language"
}

@test "will not run in strict mode by default" {
    run otelify.sh -s -- echo "hello"
    [ "$status" -eq 1 ]
}
