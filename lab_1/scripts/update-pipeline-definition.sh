#!/bin/bash

function usage {
  echo "Usage: $0 PATH_TO_PIPELINE_JSON [--configuration CONFIG] [--owner OWNER] [--branch BRANCH] [--repo REPO] [--poll-for-source-changes BOOLEAN]"
  echo "  PATH_TO_PIPELINE_JSON - Path to the pipeline JSON definition file."
  echo "  --configuration CONFIG - Build configuration value."
  echo "  --owner OWNER - GitHub account name."
  echo "  --branch BRANCH - Branch name."
  echo "  --repo REPO - GitHub repository name."
  echo "  --poll-for-source-changes BOOLEAN - Automatic pipeline execution on source code changes."
  exit 1
}

check_installed_jq() {
    if ! command -v jq &> /dev/null; then
        echo "JQ is not installed on this machine."

        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "To install JQ on Linux, run the following command:"
            echo "sudo apt-get install jq"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "To install JQ on macOS, run the following command:"
            echo "brew install jq"
        else
            echo "Unable to determine OS type."
        fi

        exit 1
    fi
}

# Remove metadata property from pipeline JSON
function remove_metadata_property() {
  jq 'del(.metadata)' "$1" > tmp.json && mv tmp.json "$2"
}

# Function to increment the pipeline version
function increment_pipeline_version() {
  jq '.pipeline.version += 1' "$1" > tmp.json && mv tmp.json "$2"
}

# Set Owner from the parameter
function set_owner() {
  jq --arg owner "$3" '.pipeline.stages[0].actions[0].configuration.Owner=$owner' "$1" > tmp.json && mv tmp.json "$2"
}

# Set Branch from the parameter
function set_branch() {
  jq --arg branch "$3" '.pipeline.stages[0].actions[0].configuration.Branch=$branch' "$1" > tmp.json && mv tmp.json "$2"
}

# Set PollForSourceChanges from the parameter
function set_poll_source() {
  jq --arg pollForSourceChanges "$3" '.pipeline.stages[0].actions[0].configuration.PollForSourceChanges=$pollForSourceChanges' "$1" > tmp.json && mv tmp.json "$2"
}

# Set EnvironmentVariables from the parameter
function set_env_variables() {
  environment_variables="{\"BUILD_CONFIGURATION\": \"$3\"}"
  jq --argjson environment_variables "$environment_variables" '.pipeline.stages[].actions[].configuration.EnvironmentVariables=$environment_variables' "$1" > tmp.json && mv tmp.json "$2"
}

# Validate if the path to the pipeline definition JSON file is provided
if [ $# -eq 0 ]; then
    echo "Error: Path to the pipeline definition JSON file is not provided."
    usage
fi

pipeline_json_file=$1

# Check if the pipeline JSON definition file exists
if [ ! -f "$pipeline_json_file" ]; then
    echo "Error: Pipeline definition JSON file not found at $pipeline_json_file."
    usage
fi


# Parse additional command line parameters
while [[ $# -gt 1 ]]; do
  key="$2"
  case $key in
    --configuration)
      configuration="$3"
      shift
      ;;
    --owner)
      owner="$3"
      shift
      ;;
    --branch)
      branch="$3"
      shift
      ;;
    --repo)
      repo="$3"
      shift
      ;;
    --poll-for-source-changes)
      poll_for_source_changes="$3"
      shift
      ;;
    *)
      usage
      ;;
  esac
  shift
done

# Load pipeline JSON definition
pipeline=$(cat $pipeline_json_file)

# Validate if the necessary properties are present in the pipeline JSON definition
if [[ -z $(echo $pipeline | jq '.metadata') ]] || [[ -z $(echo $pipeline | jq '.pipeline.version') ]] || [[ -z $(echo $pipeline | jq '.pipeline.stages[0].actions[0].configuration.Branch') ]] || [[ -z $(echo $pipeline | jq '.pipeline.stages[0].actions[0].configuration.Owner') ]] || [[ -z $(echo $pipeline | jq '.pipeline.stages[0].actions[0].inputArtifacts[0].location.s3Location.bucketName') ]]; then
    echo "Error: The necessary properties are not present in the given JSON definition."
    exit 1
fi


pipeline_name="${pipeline_json_file##*/}"
pipeline_name_no_extension="${pipeline_name%.*}"
new_pipeline_file="${pipeline_name_no_extension}-$(date +'%Y-%m-%d').json"


check_installed_jq
increment_pipeline_version "$pipeline_json_file" "$new_pipeline_file"
remove_metadata_property "$new_pipeline_file" "$new_pipeline_file"

if [ -n "$owner" ]; then
    set_owner "$new_pipeline_file" "$new_pipeline_file" "$owner"
fi

if [ -n "$branch" ]; then
    set_branch "$new_pipeline_file" "$new_pipeline_file" "$branch"
fi

if [ -n "$poll_for_source_changes" ]; then
    set_poll_source "$new_pipeline_file" "$new_pipeline_file" "$poll_for_source_changes"
fi

if [ -n "$configuration" ]; then
    set_env_variables "$new_pipeline_file" "$new_pipeline_file" "$configuration"
fi