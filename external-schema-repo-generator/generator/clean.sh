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

. ./utils.sh

# Arguments renaming
arguments_number=$#
generation_directory=$1

remove_generated_directory() {
  check_arguments $arguments_number $EXPECTED_1_ARG
  echo "Removing generated directory: $1"
  rm -rf $1
}

main() {
  check_arguments $arguments_number $EXPECTED_1_ARG
  directory_to_remove="./$generation_directory/"
  if [ -d "$directory_to_remove" ]
  then
      remove_generated_directory $directory_to_remove
  else
      echo "Nothing to clean. No directory: $directory_to_remove"
  fi
}

main
