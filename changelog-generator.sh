#!/bin/bash

# Set your desired tag prefix here
tag_prefix="dbp-moodle."

changelog_file="CHANGELOG.md"

repository_name="dbp-moodle"

org_or_user_name="dBildungsplattform"

echo "# Changelog" > "$changelog_file"
echo "" >> "$changelog_file"

# Get all tags with the specified prefix, sorted by creation date (newest last), then reverse the array
tags=($(git tag --sort=creatordate | grep "^$tag_prefix"))
tags=($(echo "${tags[@]}" | tr ' ' '\n' | tac))

# Check if we have enough tags
if [ ${#tags[@]} -lt 1 ]; then
    echo "❌ No tags found with prefix '$tag_prefix'"
    exit 1
fi

# Loop through tag pairs in reverse
for ((i=0; i<${#tags[@]}-1; i++)); do
    from_tag=${tags[$i+1]}
    to_tag=${tags[$i]}
    echo "## [$to_tag](https://github.com/$org_or_user_name/$repository_name/releases/tag/$to_tag)" >> "$changelog_file"
    echo "" >> "$changelog_file"
    echo "[Full Changelog](https://github.com/$org_or_user_name/$repository_name/compare/$from_tag...$to_tag)" >> "$changelog_file"
    git log "$from_tag".."$to_tag" --pretty=format:"- %s (%an)" | grep -E "\(#[0-9]+\)" >> "$changelog_file"
    echo -e "\n" >> "$changelog_file"
done

# Add changes from the latest tag to HEAD
latest_tag=${tags[0]}
echo "## Unreleased (Changes since $latest_tag)" >> "$changelog_file"
echo "" >> "$changelog_file"
git log "$latest_tag"..HEAD --pretty=format:"- %s (%an)" | grep -E "\(#[0-9]+\)" >> "$changelog_file"
echo -e "\n" >> "$changelog_file"

echo "✅ Changelog written to $changelog_file using tags with prefix '$tag_prefix' (only PRs included)"
