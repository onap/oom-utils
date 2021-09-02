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
EXPECTED_10_ARGS=10


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

fix_schema_references(){
  schemas=$(grep -Eo "http.*[^\/]+(.yaml)" $1/$2-*/$3/* | sort -u)
  for schema in $schemas; do
    schemaFilePath=$(echo "$schema" | awk  -F ":https:" '{print $1}')
    remotePath=$(echo "$schema" | awk  -F ".yaml:" '{print $2}')
    fileName=$(echo "$remotePath" |  grep -Eo "([^/]\w*.yaml)") 
    sed -i "s%${remotePath}%${fileName}%g" $schemaFilePath
  done
  schemas=$(grep -Eo "(\w*.yaml)" $1/$2-*/$3/* | sort -u)
  for schema in $schemas; do
    schemaFilePath=$(echo "$schema" | awk  -F ":" '{print $1}')
    wrongPath=$(echo "$schema" | awk  -F ".yaml:" '{print $2}')
    fileName="../..$(ls -d $1/$2-*/$3/* | grep $wrongPath | awk  -F "$1" '{print $2}')"
    sed -i "s%${wrongPath}%${fileName}%g" $schemaFilePath
  done
}


check5GApiBranchExistenceInRefs () {
  echo $(sed -n '/5G_APIs/p' $1/*.yaml | awk  -F "raw/|blob/" '{print $2}' | awk -F "/"  '{print $1}' | uniq)
}
