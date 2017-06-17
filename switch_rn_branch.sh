#!/bin/bash

# This script simplifies your life when you occasionally need to switch react-native project branch.
# You need to remember to do all of the following:
# 1. Go to your react-native project dir
# 2. Check if there are uncommitted changes in the current branch
# 3. Stash uncommitted changes if there are
# 4. Remove "node_modules/" dir
# 5. Checkout your target branch or tag
# 6. Install project dependencies
# 7. Kill already running react-native packager process
# 8. Start a new react-native packager process
#
# All of these steps are really annoying boilerplate operations, which you may need to perform few times a day.
# This script comes to a rescue.
#
# Sample usage: ./switch_rn_branch.sh ~/workspace/AnydoRN 1.5.0


# terminate process if any of the commands fails - to avoid executing subsequent commands when previous fails
set -e

if [ $# -lt 2 ]; then
  echo "2 parameters are required: (1)react-native project dir path; (2)Tagret branch name. Exiting."
  exit 1
fi

rn_proj_dir=$1
target_branch=$2

cd $rn_proj_dir
if [ -n "$(git status --porcelain)" ]; then
  # there are uncommitted changes
  current_branch_name=$(git rev-parse --abbrev-ref HEAD)
  echo -e "\n========= Git working tree isn't clean in "$rn_proj_dir" repo ========="
  echo -e "========= Stashing the uncommitted changes for branch "$current_branch_name" : =========\n"
  git stash -u
fi

# git working tree is clean
rm -rf node_modules/ # required to avoid dependencies conflict
echo -e "\n========= Checking out branch/tag "$target_branch" : =========\n"
git checkout $target_branch
dependencies_install_msg_prefix="\n========= Installing the dependencies using "
if [ -f ./yarn.lock ]; then
  echo -e $dependencies_install_msg_prefix"YARN: =========\n"
  yarn
else
  echo -e $dependencies_install_msg_prefix"NPM: =========\n"
  npm install
fi

# kill already running packager process (if exists)
rn_packager_default_port=8081
set +e # avoid terminating this script process if there's no packager currently running
running_packager_process_pid=$(lsof -ti :$rn_packager_default_port)
set -e # reset
if [ -n "$running_packager_process_pid" ]; then
  echo -e "\n========= Running ReactNative packager process detected, killing it. =========\n"
  kill -9 $running_packager_process_pid
fi

echo -e "\n========= Starting the new ReactNative packager process: =========\n"
npm start
