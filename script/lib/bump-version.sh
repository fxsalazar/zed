#!/bin/bash

set -eu

if [[ $# < 4 ]]; then
  echo "Missing version increment (major, minor, or patch)" >&2
  exit 1
fi

package=$1
tag_prefix=$2
tag_suffix=$3
version_increment=$4

if [[ -n $(git status --short --untracked-files=no) ]]; then
  echo "Can't push a new version with uncommitted changes"
  exit 1
fi

which cargo-set-version > /dev/null || cargo install cargo-edit
cargo set-version --package $package --bump $version_increment
cargo check --quiet

new_version=$(script/get-crate-version $package)
branch_name=$(git rev-parse --abbrev-ref HEAD)
old_sha=$(git rev-parse HEAD)
tag_name=${tag_prefix}${new_version}${tag_suffix}

git commit --quiet --all --message "${package} ${new_version}"
git tag ${tag_name}

cat <<MESSAGE
Locally committed and tagged ${package} version ${new_version}

To push this:
    git push origin \
      ${tag_name} \
      ${branch_name}

To undo this:
    git tag -d ${tag_name} && \
      git reset --hard ${old_sha}
MESSAGE