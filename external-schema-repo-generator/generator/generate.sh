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
repo_url=$1
branches=$2
schemas_location=$3
vendor=$4
configmap_filename=$5
configmap_name=$6
snippet_filename=$7
specs_directory=$8
generation_directory=$9
_5g_api_repo_url=${10}

# Constants
SCHEMA_MAP_FILENAME="schema-map.json"
SCHEMA_MAP_NAME="schema-map"
SUCCESS_CODE=0
TREE=blob
INDENTATION_LEVEL_1=1
INDENTATION_LEVEL_2=2
INDENTATION_LEVEL_3=3
INDENTATION_LEVEL_4=4
INDENTATION_LEVEL_5=5

# Variables
tmp_location=$(mktemp -d)
valid_branches=""

# Create and move to directory for storing generated files
move_to_generation_directory() {
  mkdir "$generation_directory"
  cd ./"$generation_directory"
}

# Indents each line of string by adding indent_size*indent_string spaces on the beginning
# Optional argument is indent_string level, default: 1
# correct usage example:
# echo "Sample Text" | indent_string 2
indent_string() {
  indent_size=2
  indent_string=1
  if [ -n "$1" ]; then indent_string=$1; fi
  pr -to $(expr "$indent_string" \* "$indent_size")
}

# Clones all branches selected in $BRANCH from $repo_url
clone_repo() {
  for actual_branch in $branches; do
    clone_branch "$actual_branch"
  done
  #schemas=$(ls -g $tmp_location/$actual_branch/$schemas_location/*.yaml | awk '{print $NF}')
  #for schema in $schemas; do
  #  resolve_remote_refs "$schema" "$tmp_location"
  #done
  #scheamaHelperDirs

}

# Clones single branch $1 from $repo_url.
# $1 - branch name
clone_branch() {
  check_arguments $# $EXPECTED_1_ARG
  configmapSize=800000
  branch=""
  # check if OPEN API branch value provided by user contains 5G API branch after colon for example: Rel-16-SA-91:TSG91-Rel16
  if [ -z "${1##*":"*}" ]; then
    OpenApiBranch=${1%:*}
    _5GApiBranch=${1#"$OpenApiBranch"}
    _5GApiBranch=${_5GApiBranch#:}
    if [ -d $tmp_location/"$OpenApiBranch" ]; then
      echo "Skipping cloning repository."
      echo "Branch $OpenApiBranch has already been cloned in the directory ./$tmp_location/$OpenApiBranch"
      echo "To redownload branch remove ./$tmp_location/$OpenApiBranch."
    else
      echo "Cloning repository from branch $OpenApiBranch"
      git clone --quiet --single-branch --branch "$OpenApiBranch" "$repo_url" "$tmp_location/$OpenApiBranch" 2>/dev/null
      OpenApiBranchResult=$?
      # clones 5G API branch moves schemas to OPEN API, splits folder to folder less than 1mb
      echo "Cloning repository from branch $_5GApiBranch"
      git clone --quiet --single-branch --branch "$_5GApiBranch" "$_5g_api_repo_url" "$tmp_location/$OpenApiBranch/$schemas_location/$_5GApiBranch" 2>/dev/null
      _5GApiBranchResult=$?
      mv $tmp_location/$OpenApiBranch/$schemas_location/$_5GApiBranch/*.yaml $tmp_location/$OpenApiBranch/$schemas_location/
      dirSize=$(du -bs $tmp_location/$OpenApiBranch/$schemas_location/ | cut -f1)
      if [ "$configmapSize" -le "$dirSize"  ]; then
	find $tmp_location/$OpenApiBranch/$schemas_location/ -type f -iname '*yaml' -printf "%s %p\n" | awk -v c=$configmapSize -v tmpLocation=$tmp_location -v schema=$OpenApiBranch -f bin_packing.awk
	# adds each folder as valid branch to generate separate configmap (less then 1 mb) for each folder
	for i in $(ls -d -p $tmp_location/${OpenApiBranch}-* |  grep -Eo '[^/]+/?$' | cut -d / -f1); do branch="${branch} $i"; done
      else
	branch=$OpenApiBranch
      fi
      # fix schema file references both remote and local against folder structure for whole schema
      fix_schema_references $tmp_location $OpenApiBranch $schemas_location
      if  [ $OpenApiBranchResult -ne $SUCCESS_CODE ] && [ $_5GApiBranchResult -ne $SUCCESS_CODE ] ; then
        echo "Problem with cloning branch $OpenApiBranch."
        echo "Branch $OpenApiBranch= will not be added to spec."
      else
        valid_branches="${valid_branches} $branch"
        echo "valid_branches: $valid_branches"
      fi
    fi
  else
    OpenApiBranch=$1
    if [ -d $tmp_location/"$OpenApiBranch" ]; then
      echo "Skipping cloning repository."
      echo "Branch $OpenApiBranch has already been cloned in the directory ./$tmp_location/$OpenApiBranch"
      echo "To redownload branch remove ./$tmp_location/$OpenApiBranch."
    else
      echo "Cloning repository from branch $OpenApiBranch"
      git clone --quiet --single-branch --branch "$OpenApiBranch" "$repo_url" "$tmp_location/$OpenApiBranch" 2>/dev/null
      OpenApiBranchResult=$?
      branch=""
      # script checks schema files if they don’t contain remote refs to 5G API even user didn't define it after colon for example: Rel-16-SA-91:TSG91-Rel16
      # if contain then script parse repo tag from reference checkouts it, split to folders, resolve refs and cerates configmap for each folder
      _5GApiBranch=$(check5GApiBranchExistenceInRefs "$tmp_location/$OpenApiBranch/$schemas_location")
      if [ ! -z "$_5GApiBranch" ]; then
	echo "Cloning repository from branch $_5GApiBranch"
        git clone --quiet --single-branch --branch "$_5GApiBranch" "$_5g_api_repo_url" "$tmp_location/$OpenApiBranch/$schemas_location/$_5GApiBranch" 2>/dev/null
	_5GApiBranchResult=$?
        mv $tmp_location/$OpenApiBranch/$schemas_location/$_5GApiBranch/*.yaml $tmp_location/$OpenApiBranch/$schemas_location
        dirSize=$(du -bs $tmp_location/$OpenApiBranch/$schemas_location/ | cut -f1)
        if [ "$configmapSize" -le "$dirSize"  ]; then
          find $tmp_location/$OpenApiBranch/$schemas_location/ -type f -iname '*yaml' -printf "%s %p\n" | awk -v c=$configmapSize -v tmpLocation=$tmp_location -v schema=$OpenApiBranch -f bin_packing.awk
          for i in $(ls -d -p $tmp_location/${OpenApiBranch}-* |  grep -Eo '[^/]+/?$' | cut -d / -f1); do branch="${branch} $i"; done
        else
          branch=$OpenApiBranch
        fi
        fix_schema_references $tmp_location $OpenApiBranch $schemas_location
	if  [ ! -z "$_5GApiBranch" ] && [ $_5GApiBranchResult -ne $SUCCESS_CODE ] && [ $OpenApiBranchResult -ne $SUCCESS_CODE ]  ; then
          echo "Problem with cloning branch $OpenApiBranch."
          echo "Branch $OpenApiBranch= will not be added to spec."
        else
          valid_branches="${valid_branches} $branch"
          echo "valid_branches: $valid_branches"
        fi
      #if schema files don't contain remote refs to 5G API script goes with old path and doesn't checkout 5G API branch
      else
        if  [ $OpenApiBranchResult -ne $SUCCESS_CODE ] ; then
          echo "Problem with cloning branch $OpenApiBranch."
          echo "Branch $OpenApiBranch= will not be added to spec."
        else
          valid_branches="${valid_branches} $OpenApiBranch"
	  echo "valid_branches: $valid_branches"
        fi
      fi
    fi
  fi
}

# Creates file with name $configmap_filename
# Inserts ConfigMap metadata and sets name as $configmap_name
# $1 - branch name
add_config_map_metadata() {
  branch_configmap_filename="${configmap_filename}-$1.yaml"
  branch_configmap_name=$( echo "$configmap_name-$1" | tr '[:upper:]' '[:lower:]' )
  echo "Creating ConfigMap spec file: $branch_configmap_filename"
  cat << EOF > "$branch_configmap_filename"
apiVersion: v1
kind: ConfigMap
metadata:
  name: $branch_configmap_name
  labels:
    name: $branch_configmap_name
  namespace: onap
data:
EOF
}

# For each selected branch:
#   clones the branch from repository,
#   adds schemas from branch to ConfigMap spec
# $1 - branch name
add_schemas() {
  echo "Adding schemas from branch $1 to spec"
  add_schemas_from_branch "$1"
}

# Adds schemas from single branch to spec
# $1 - branch name
add_schemas_from_branch() {
  branch_configmap_filename="${configmap_filename}-$1.yaml"
  check_arguments $# $EXPECTED_1_ARG
  schemas=$(ls -g $tmp_location/$1/$schemas_location/*.yaml | awk '{print $NF}')
  for schema in $schemas; do
    echo "$(basename $schema): |-" | indent_string $INDENTATION_LEVEL_1
    cat "$schema" | indent_string $INDENTATION_LEVEL_2
  done
} >> "$branch_configmap_filename"

move_to_spec_directory() {
  mkdir "$specs_directory"
  cd ./"$specs_directory"
}

# Generates mapping file for collected schemas directly in spec
# $1 - schema map name
generate_mapping_file() {
  schema_map_filename="${configmap_filename}-$1.yaml"
  echo "Generating mapping file in spec"
  echo "$SCHEMA_MAP_FILENAME"": |-" | indent_string $INDENTATION_LEVEL_1 >> "$schema_map_filename"
  echo "[" | indent_string $INDENTATION_LEVEL_2 >> "$schema_map_filename"

  for actual_branch in $valid_branches; do
    echo "Adding mappings from branch: $actual_branch"
    add_mappings_from_branch $actual_branch $schema_map_filename
  done

  truncate -s-2 "$schema_map_filename"
  echo "" >> "$schema_map_filename"
  echo "]" | indent_string $INDENTATION_LEVEL_2 >> "$schema_map_filename"
}

# Adds mappings from single branch directly to spec
# $1 - branch name
# $2 - schema map file name
add_mappings_from_branch() {
  check_arguments $# $EXPECTED_2_ARGS
  schema_map_filename="$2"
  schemas=$(ls -g $tmp_location/$1/$schemas_location/*.yaml | awk '{print $NF}' )

  for schema in $schemas; do
    repo_endpoint=$(echo "$repo_url" | cut -d/ -f4- | rev | cut -d. -f2- | rev)
    schema_repo_path=$(echo "$schema" | cut -d/ -f4-)
    schema_repo_path_fixed=$(echo "$schema_repo_path" | sed -r "s%"-subdir-[0-9]"%%" )
    public_url_schemas_location=${repo_url%.*}
    public_url=$public_url_schemas_location/$TREE/$schema_repo_path_fixed
    local_url=$vendor/$repo_endpoint/$TREE/$schema_repo_path

    echo "{" | indent_string $INDENTATION_LEVEL_3 >> "$schema_map_filename"
    echo "\"publicURL\": \"$public_url\"," | indent_string $INDENTATION_LEVEL_4 >> "$schema_map_filename"
    echo "\"localURL\": \"$local_url\"" | indent_string $INDENTATION_LEVEL_4 >> "$schema_map_filename"
    echo "}," | indent_string $INDENTATION_LEVEL_3 >> "$schema_map_filename"
  done
}

# Create snippet file to describe how to connect mount ConfigMaps in VES
create_snippet() {
  echo "Generating snippets in file: $snippet_filename"
  generate_entries
  base_mounts_path="/opt/app/VESCollector/etc/externalRepo"
  base_mounts_name="external-repo-$vendor-schemas"
  mounts_paths="
        - mountPath: $base_mounts_path
          name: $base_mounts_name"

  config_maps="
      - configMap:
          defaultMode: 420
          name: $configmap_name-$SCHEMA_MAP_NAME
        name: $base_mounts_name"

  for actual_branch in $valid_branches; do

    actual_branch_name=$( echo "$actual_branch" | tr '[:upper:]' '[:lower:]' )

    repo_endpoint=$(echo "$repo_url" | cut -d/ -f4- | rev | cut -d. -f2- | rev)
    local_url=$vendor/$repo_endpoint/$TREE/$actual_branch/$schemas_location
    mounts_paths="$mounts_paths
        - mountPath: $base_mounts_path/$local_url
          name: $base_mounts_name-$actual_branch_name"

    config_maps="$config_maps
      - configMap:
          defaultMode: 420
          name: $configmap_name-$actual_branch_name
        name: $base_mounts_name-$actual_branch_name"
  done


  cat << EOF > "$snippet_filename"
Snippets for mounting ConfigMap in DCAE VESCollector Deployment
=========================================================================

## Description
These snippets will override existing in VESCollector schemas and mapping file.

No extra configuration in VESCollector is needed with these snippets.

## Snippets
#### spec.template.spec.containers[0].volumeMounts
\`\`\`$mounts_paths
\`\`\`

#### spec.template.spec.volumes
\`\`\`$config_maps
\`\`\`
EOF
}

generate_entries() {
  for actual_branch in $valid_branches; do
    schemas=$(ls -g $tmp_location/$actual_branch/$schemas_location/*.yaml | awk '{print $NF}')
    for schema in $schemas; do
      repo_endpoint=$(echo "$repo_url" | cut -d/ -f4- | rev | cut -d. -f2- | rev)
      schema_repo_path=$(echo "$schema" | cut -d/ -f4-)

      key="$actual_branch-$(basename "$schema")"
      path=$vendor/$repo_endpoint/$TREE/$schema_repo_path
      schemas_entries="$schemas_entries- key: $key\n  path: $path\n"
    done
  done
  schemas_entries=$(echo "$schemas_entries" | indent_string $INDENTATION_LEVEL_5)
}

# Generate specs for branch
# $1 - branch name
generate_specs_for_branch() {
  check_arguments $# $EXPECTED_1_ARG
  add_config_map_metadata $1
  add_schemas $1
}

# Generate specs for schema map
generate_specs_for_schema_map() {
  add_config_map_metadata "$SCHEMA_MAP_NAME"
  generate_mapping_file "$SCHEMA_MAP_NAME"
}

# Generate specs for all releases and for schema map
generate_specs() {
  move_to_spec_directory
  for actual_branch in $valid_branches; do
    generate_specs_for_branch $actual_branch
  done
  generate_specs_for_schema_map
  cd ..
}


# todo add check of global env whether script should be ran
main() {
  check_arguments $arguments_number $EXPECTED_10_ARGS
  clone_repo
  move_to_generation_directory
  generate_specs
  create_snippet
  move_to_starting_directory
}

main
