#!/bin/bash
#Simplified validation script for the landing zone

abort() {
  echo "$1"
  exit 1
}

check_exec() {
  echo "Checking $1..."
  command -v "$1" >/dev/null 2>&1;
}

check_env() {
  echo "Checking environment"
  CHECK_EXECS="python python3 ruby gem grep cfn_nag_scan tr cut"
  for x in $CHECK_EXECS
  do
    check_exec "$x" || abort "Unable to find $x"
  done
}

validate_yaml() {
  local file_path="$1"

  python3 -c 'import yaml,sys;yaml.safe_load(sys.stdin)' < "$file_path"
  if [ $? -ne 0 ] 
  then
    abort "$file_path is not valid YAML"      
  fi
  
  echo "$file_path is a valid YAML"
}

validate_manifest() {
  local manifest_path="$1"

  #Validate YAML
  validate_yaml "$manifest_path"

  #Validate manifest schema
  pykwalify -d "$manifest_path" -s /validation/manifest.schema.yaml -e /validation/custom_validation.py
  if [ $? -ne 0 ]
  then
    echo "Manifest file failed schema validation"
    exit 1
  fi
  echo "Manifest file validated against the schema successfully"
} 

validate_manifest_files() {
  local manifest_path="$1/manifest.yaml"
        
  # The manifest can contain references to both local files and 
  # remote files in s3. Extract local files from the manifest for validation.

  # check each template/json file in the manifest to assert existance
  local check_files=$(grep '_file:' < $manifest_path | grep -v '^ *#' | tr -s ' ' | tr -d '\r' | cut -d ' ' -f 3 | grep -v '^s3*' | grep -Ev '*.j2')
  
  # check each template/json file in the manifest to assert existance and check syntax
  for f in $check_files ; do
  echo "Validating $f"
  if [[ $f == *.template ]]; then
    echo "Running cfn_nag_scan on $1/$f"
    cfn_nag_scan --input-path "$1/$f" || abort "CFN Nag failed validation - $1/$f"
  elif [[ $f == *.json ]]; then
    echo "Running json validation on $1/$f"
    python3 -m json.tool < "$1/$f" || abort "CloudFormation parameter file failed validation - $1/$f"
  else
      abort "Unsupported file extension - $f"
  fi
  done
}

REPOSITORY_PATH="$1"

if [ -z $REPOSITORY_PATH ]; then
  abort "You must provide the repository path, where the manifest.yaml file is located"
fi  

echo "Checking repository in $REPOSITORY_PATH"
validate_manifest "$REPOSITORY_PATH/manifest.yaml"
validate_manifest_files "$REPOSITORY_PATH"
