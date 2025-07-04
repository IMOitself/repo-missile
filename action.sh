#!/bin/sh -l

set -e # if a command fails, exit the script

# --- CONFIGS & INPUTS ---
SOURCE_FILES="$1"
DESTINATION_USERNAME="$2"
DESTINATION_REPOSITORY="$3"
DESTINATION_BRANCH="$4"
DESTINATION_DIRECTORY="$5" 
COMMIT_USERNAME="$6"
COMMIT_EMAIL="$7"
COMMIT_MESSAGE="$8"
API_TOKEN_GITHUB="$API_TOKEN_GITHUB"

HASH_FILE_PATH=".github/workflows/repo-missile/DONT-DELETE.latestcommithash"
SYNC_BRANCH="repo-missile"


if [ -z "$COMMIT_USERNAME" ]; then
  COMMIT_USERNAME="$DESTINATION_USERNAME"
fi

git config --global user.email "$COMMIT_EMAIL"
git config --global user.name "$COMMIT_USERNAME"

# Remove git directory if it exists to prevent errors
rm -rf .git





# --- SCRIPT START ---

echo "--- DETERMINING ACTION TO MAKE ---"

echo "Cloning source and target repositories..."
git clone "https://$API_TOKEN_GITHUB@github.com/$GITHUB_REPOSITORY.git" source-repo
git clone --single-branch --branch "$DESTINATION_BRANCH" "https://$API_TOKEN_GITHUB@github.com/$DESTINATION_USERNAME/$DESTINATION_REPOSITORY.git" target-repo

cd source-repo

action_type=""

if [ ! -f "$HASH_FILE_PATH" ]; then
    echo "tracking file not found at '$HASH_FILE_PATH' of this repo."
    echo "probably because this is the first time running this action."
    echo "doing initial setup..."
    LATEST_SOURCE_HASH=$(git rev-parse HEAD)
    echo "$LATEST_SOURCE_HASH" > "$HASH_FILE_PATH"
    action_type="INIT"
fi

cd target-repo

if [ ! -f "$HASH_FILE_PATH" ]; then
    echo "tracking file not found at '$HASH_FILE_PATH' of destination repo."
    echo "probably because this is the first time running this action."
    echo "doing initial setup..."
    LATEST_TARGET_HASH=$(git rev-parse HEAD)
    echo "$LATEST_TARGET_HASH" > "$HASH_FILE_PATH"
    action_type="INIT"
fi

if [ "$action_type" = "INIT" ]; then
    echo "--- INITIAL SETUP COMPLETED ---"
    exit 0
fi