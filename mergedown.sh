#!/usr/bin/env bash
set -e

if [ -z ${GITHUB_TOKEN} ]; then
  echo "Missing GITHUB_TOKEN. Aborting merge."
  exit
fi

if [ -z ${GITHUB_REPO} ]; then
  echo "Missing target github repo in the form 'user/name'"
  exit
fi

export GIT_COMMITTER_EMAIL='sam@ci'
export GIT_COMMITTER_NAME='SamOnCI'

# Merge targets -> current=target
export master=test
export test=develop

merge_target=${!TRAVIS_BRANCH}

if [ -z ${merge_target} ]; then
  echo "No merge target for branch ${TRAVIS_BRANCH}. Cancelling automerge"
  exit
fi

echo "cloning repository"
# Since Travis does a partial checkout, we need to get the whole thing
repo_temp=$(mktemp -d)
git clone "https://${GITHUB_TOKEN}@github.com/$GITHUB_REPO" "$repo_temp"

cd "$repo_temp"

echo "Checking out ${merge_target}" 
git checkout ${merge_target}

echo "Merging ${TRAVIS_COMMIT}"
git merge --ff-only "$TRAVIS_COMMIT" --porcelain

echo "Pushing to ${GITHUB_REPO}"
push_uri="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO}"

# Redirect to /dev/null to avoid secret leakage
# Also we don't care if it fails really.
set +e
git push \"${push_uri}\" \"${merge_target}\" >/dev/null 2>&1
