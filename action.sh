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

initialize_repo_missile_if_needed() {
    local repo_dir="$1"

    (
    set -e
    cd "$repo_dir"

    if [ ! -f "$HASH_FILE_PATH" ]; then
      echo "--- $repo_dir has no tracking file."
      echo "--- probably because this is the first time running this action."
      echo "--- INITIALIZING TRACKING FILE FOR $repo_dir ---"

      mkdir -p "$(dirname "$HASH_FILE_PATH")"
      git log -1 --format=%H -- "$SOURCE_FILES" > "$HASH_FILE_PATH"

      git add "$HASH_FILE_PATH"
      git commit -m "repo-missile: initialize tracking file"
      git push
      return 0
    fi
    return 1
    )
}


init_occurred=false

REPOS=( "source-repo" "target-repo" )

for repo in "${REPOS[@]}"; do
  if initialize_repo_missile_if_needed "$repo"; then
    init_occurred=true
  fi
done

if [ "$init_occurred" = true ]; then
  echo "--- INITIAL SETUP COMPLETED ---"
  exit 0
fi





echo "--- CHECKING FOR NEW COMMITS ---"

cd target-repo

echo "TARGET REPO COMMITS:"
git log -5 --oneline --no-merges -- "$SOURCE_FILES"
echo ""

TARGET_LAST_SYNC_COMMIT_HASH=$(cat "$HASH_FILE_PATH")
TARGET_LAST_SYNC_COMMIT_DATE=$(git log "$TARGET_LAST_SYNC_COMMIT_HASH"..HEAD --oneline --no-merges -- "$SOURCE_FILES")
echo "--- Last sync commit date in target-repo is: $TARGET_LAST_SYNC_COMMIT_DATE"

cd ..
cd source-repo

echo "SOURCE REPO COMMITS:"
git log -5 --oneline --no-merges -- "$SOURCE_FILES"
echo ""

SOURCE_NEWER_COMMIT_HASHES=$(git log --since="$TARGET_LAST_SYNC_COMMIT_DATE" --format=%H --reverse --no-merges)

if [ -z "$SOURCE_NEWER_COMMIT_HASHES" ]; then
    echo "--- No new commits found in source-repo. Exiting."
    exit 0
fi

echo "--- Found newer commits in source-repo to be applied:"
git log --since="$TARGET_LAST_SYNC_COMMIT_DATE" --oneline --no-merges
