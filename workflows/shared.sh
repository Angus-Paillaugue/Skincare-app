#!/usr/bin/env bash

# Variables
app_name="Skincare-app"
project_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release_branch="main"

get_latest_version() {
  local latest_version
  latest_version=$(curl -s "https://raw.githubusercontent.com/Angus-Paillaugue/$app_name/refs/heads/$release_branch/VERSION")
  strip_latest_version="$(echo "$latest_version" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+')"
  echo "$strip_latest_version"
}

get_local_version() {
  local local_version
  file_path="$project_dir/VERSION"
  if [[ -f "$file_path" ]]; then
    local_version=$(cat "$file_path")
  else
    local_version="0.0.0" # Default version if file does not exist
  fi
  echo "$local_version"
}
