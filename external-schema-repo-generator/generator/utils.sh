#!/bin/sh

# ============LICENSE_START=======================================================
# OOM
# ================================================================================
# Copyright (C) 2021 Nokia. All rights reserved.
# ================================================================================
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#      http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============LICENSE_END=========================================================

# Variables
starting_directory="$PWD"

# Constants
EXPECTED_1_ARG=1
EXPECTED_2_ARGS=2
EXPECTED_4_ARGS=4
EXPECTED_9_ARGS=9


# Checks whether number of arguments is valid
# $1 is actual number of arguments
# $2 is expected number of arguments
check_arguments() {
  if [ "$1" -ne "$2" ]; then
    echo "Incorrect number of arguments"
    exit 1
  fi
}

# Go back to directory from which script was called
move_to_starting_directory() {
  echo "Moving back to: $starting_directory"
  cd $starting_directory
}
