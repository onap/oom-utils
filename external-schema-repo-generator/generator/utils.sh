#!/bin/bash

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

# Looks in schema file for remote refs.
# Downloads remote refs to schem directory
# Replace remote refs locations with local locations
resolve_remote_refs() {
  check_arguments $# $EXPECTED_1_ARG
  filename=$1
  declare -a FqdnArray=()
  exec 4<"$filename"
# look for remote refs in schema file
  while read -u4 p ; do
    [[ $p  =~ (\$ref:.*)(https:\/\/forge\.3gpp\.org[^#]*) ]]
    if [[ ! -z "${BASH_REMATCH[2]}" ]]
    then
      FqdnArray+=(${BASH_REMATCH[2]})
    fi
  done
# remove duplicates of remote refs
  UniqFqdnArray=($(printf "%s\n" "${FqdnArray[@]}" | sort -u | tr '\n' ' '))
# get schema directory from file path
  [[ $filename =~ (.+\/\/)*(.+)\/ ]]
  SchemaDirectory=${BASH_REMATCH[2]}
  for val in ${UniqFqdnArray[@]}; do
# get file name
    wget -N $val -P $SchemaDirectory
    [[ $val  =~ ^h.*:\/\/(.+\/\/)*(.+)\/(.+)$ ]]
    search=$val
    replace=${BASH_REMATCH[3]}
    sed -i "s%${search}%${replace}%g" $filename
  done
  [[ $filename =~ (.+\/\/)*(.+)\/(.+)$ ]]
  SchemaFileName=${BASH_REMATCH[3]}
  if [[$SchemaFileName == "comDefs.yaml"]]
  then
     sed -i "%provMnS%d" $filename
     sed -i "%perfMnS%d" $filename
  fi
}
