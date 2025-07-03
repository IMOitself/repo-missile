#!/bin/sh -l

set -e  # if a command fails exit the script
set -u  # script fails if trying to access an undefined variable

echo
echo "##### Starting #####"
SOURCE_FILES="$1"
DESTINATION_USERNAME="$2"
DESTINATION_REPOSITORY="$3"
DESTINATION_BRANCH="$4"
DESTINATION_DIRECTORY="$5"
COMMIT_USERNAME="$6"
COMMIT_EMAIL="$7"
COMMIT_MESSAGE="$8"

if [ -z "$COMMIT_USERNAME" ]
then
  COMMIT_USERNAME="$DESTINATION_USERNAME"
fi

CLONE_DIRECTORY=$(mktemp -d)

echo
echo "##### Cloning source git repository #####"
# Setup git
git config --global user.email "$COMMIT_EMAIL"
git config --global user.name "$COMMIT_USERNAME"

# Remove git directory if it exists to prevent errors
rm -rf .git

git clone "https://$API_TOKEN_GITHUB@github.com/$GITHUB_REPOSITORY.git" repo

cd repo
ls -la

echo
echo "##### Cloning destination git repository #####"

git clone --single-branch --branch "$DESTINATION_BRANCH" "https://$API_TOKEN_GITHUB@github.com/$DESTINATION_USERNAME/$DESTINATION_REPOSITORY.git" "$CLONE_DIRECTORY"
ls -la "$CLONE_DIRECTORY"

echo
echo "##### Copying contents to git repo #####"
mkdir -p "$CLONE_DIRECTORY/$DESTINATION_DIRECTORY"
# Replace rsync command with cp and remove .git if present:
cp -rv "$SOURCE_FILES/." "$CLONE_DIRECTORY/$DESTINATION_DIRECTORY"
rm -rf "$CLONE_DIRECTORY/$DESTINATION_DIRECTORY/.git"
cd "$CLONE_DIRECTORY"

echo
echo "##### Adding git commit #####"

ORIGIN_COMMIT="https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA"
COMMIT_MESSAGE="${COMMIT_MESSAGE/ORIGIN_COMMIT/$ORIGIN_COMMIT}"

git add .
git status

# don't commit if no changes were made
git diff-index --quiet HEAD || git commit --message "$COMMIT_MESSAGE"

echo
echo "##### Pushing git commit #####"
# --set-upstream: sets the branch when pushing to a branch that does not exist
git push origin --set-upstream "$DESTINATION_BRANCH"