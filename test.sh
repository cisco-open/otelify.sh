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

WITH_INTEGRATION=1

INTEGRATION_TEST_URL=${INTEGRATION_TEST_URL:-"https://github.com/cisco-open/"}

FULL_IMAGE_NAME=bats/bats:1.11.0

# Check if we are doing a quick check, if so we will skip the integration tests.
for arg in "$@"; do
  if [ "$arg" = "-q" ] || [ "$arg" = "--quick" ]; then
    echo "No integration tests will be run"
    WITH_INTEGRATION=0
    break # Exit the loop if -q or --quick is found
  fi
done

DOCKER_COMMAND="docker"

# Check if we have permissions to run Docker without sudo, note that this check will also fail if Docker is not installed or running.
if ! docker info &>/dev/null; then
  echo "You do not have permissions to run Docker without sudo. Trying with sudo..."
  DOCKER_COMMAND="sudo docker"
fi

if [ ${WITH_INTEGRATION} -eq 1 ]; then
  FULL_IMAGE_NAME="otelify-bats:latest"
  ${DOCKER_COMMAND} build -t "$FULL_IMAGE_NAME" .
fi

${DOCKER_COMMAND} run -it -e WITH_INTEGRATION="${WITH_INTEGRATION}" -e INTEGRATION_TEST_URL="${INTEGRATION_TEST_URL}" -e BATS_LIB_PATH=/usr/lib/bats -v "${PWD}:/code" "${FULL_IMAGE_NAME}" test
