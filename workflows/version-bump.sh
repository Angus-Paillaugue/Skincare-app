#!/usr/bin/env bash

project_dir="$(builtin cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$project_dir/workflows/shared.sh"

echo "Project directory: $project_dir"
current_local_version=$(get_local_version)
current_latest_version=$(get_latest_version)

if [[ -z "$current_latest_version" ]]; then
  echo "Error: Unable to fetch the latest version."
  exit 1
fi

if [[ -z "$current_local_version" ]]; then
  echo "Error: Local version file not found."
  exit 1
fi

update_versions_in_files() {
  local new_version="$1"

  echo "$new_version" > "$project_dir/VERSION"
  sed -i -E "s/^version: .*/version: $new_version/" "$project_dir/pubspec.yaml"
}

main() {
  git checkout "$release_branch" || {
    echo "Error: Unable to checkout the release branch '$release_branch'."
    exit 1
  }
  git pull origin "$release_branch" || {
    echo "Error: Unable to pull the latest changes from the release branch '$release_branch'."
    exit 1
  }
  local new_version
  read -p "Enter the new version (current: $current_local_version, latest: $current_latest_version): " new_version
  bump_branch="version-bump-$new_version"
  git checkout -b "$bump_branch" || {
    echo "Error: Unable to create a new branch for version bump."
    exit 1
  }
  if [[ -z "$new_version" ]]; then
    echo "No version entered. Exiting."
    exit 0
  fi
  if [[ "$new_version" == "$current_local_version" ]]; then
    echo "The new version is the same as the current version. No changes made."
    exit 0
  fi
  if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version format. Please use semantic versioning (e.g., 1.0.0)."
    exit 1
  fi
  update_versions_in_files "$new_version"

  # Commit and push the changes
  git add .
  git commit -m "Bump version to $new_version"
  git push origin "$bump_branch"

  # Create a pull request and merge it
  gh pr create --base "$release_branch" --head "$bump_branch" --title "Version Bump to $new_version" --body "This PR bumps the version to $new_version."
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create a pull request."
    exit 1
  fi
  gh pr merge --auto --squash "$bump_branch"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to merge the pull request."
    exit 1
  fi

  # Push the changes to the release branch
  git checkout "$release_branch"
  git pull origin "$release_branch"
  git branch -D "$bump_branch"
  git push origin --delete "$bump_branch"

  # Create a github release
  notes=$(git log --pretty=format:"%h - %s (%an)" "$current_local_version"..HEAD)
  gh release create "$new_version" --generate-notes || {
    echo "Error: Failed to create a GitHub release."
    exit 1
  }
  echo "Version bumped to $new_version and changes pushed to the release branch '$bump_branch'."
}

main "$@"
