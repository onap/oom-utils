#!/bin/sh

# ============LICENSE_START=======================================================
# OOM
# ================================================================================
# Copyright (C) 2020-2021 Nokia. All rights reserved.
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
spec_configmap_filename=$1
k8s_configmap_name=$2
specs_directory=$3
generation_directory=$4

# Constants
MAX_CONFIG_MAP_UPDATE_SIZE=262144 # If ConfigMaps is bigger then this value (in Bytes) it can not be updated
MAX_SPEC_SIZE=1048576 # 1MB

# Alias
alias kubectl_onap="kubectl -n onap"

# Checks whether ConfigMap exists
# When file does not exist exits with return code 1
# $1 - name of spec_configmap_filename
check_if_spec_exists() {
  check_arguments $# $EXPECTED_1_ARG
  spec_filename="$1"
  if [ ! -f "$spec_filename" ]; then
    echo "Spec file $spec_filename does not exist."
    # todo add location of spec with filename
    exit 1
  fi
}

# If spec file is to big to be apply it needs to be created
# If ConfigMap with same name exists, iot needs do be destroyed
# $1 - name of spec file
create_config_map() {
  echo "ConfigMap spec file is too long for 'kubectl apply'. Actual spec length: $spec_size, max spec length: $MAX_CONFIG_MAP_UPDATE_SIZE"
  echo "Creating new ConfigMap $k8s_configmap_name"
  kubectl_onap replace --force -f "$spec_filename"
}

# Install ConfigMap from spec
# $1 - name of spec file
# $2 - size of spec file
install_config_map() {
  check_arguments $# $EXPECTED_2_ARGS
  spec_filename="$1"
  spec_size="$2"
  if [ "$spec_size" -le $MAX_CONFIG_MAP_UPDATE_SIZE ]; then
    echo "Applying ConfigMap $k8s_configmap_name"
    kubectl_onap apply -f "$spec_filename"  
  else
    create_config_map
  fi
}

# Uploads ConfigMap spec to Kubernetes
# $1 - name of spec_configmap_filename
upload_config_map() {
  check_arguments $# $EXPECTED_1_ARG
  spec_filename="$1"
  spec_size=$(stat --printf="%s" "$spec_filename")
  if [ "$spec_size" -le "$MAX_SPEC_SIZE" ]; then
    install_config_map $spec_filename $spec_size
  else
      echo "WARNING!!!!"
      echo "  Config file is to big to be installed"
      echo "  Config file size is: $spec_size Bytes"
      echo "  Max size is: $MAX_SPEC_SIZE Bytes"
  fi
}

# install all specs located in generated specs directory
# $1 - branch name
install_all_spec_in_directory() {
  FILES="./*"
  for f in $FILES
  do
    echo "installing $f"
    check_if_spec_exists $f
    upload_config_map $f
  done
}

# Moving to directory containing specs
move_to_specs_directory() {
  target_directory="$generation_directory/$specs_directory"
  echo "Moving to directory containing specs: $target_directory"
  cd ./"$target_directory"
}

main() {
  check_arguments $arguments_number $EXPECTED_4_ARGS
  move_to_specs_directory
  install_all_spec_in_directory
  move_to_starting_directory
}

main
