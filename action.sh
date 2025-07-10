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


if [ -z "$COMMIT_USERNAME" ]; then
  COMMIT_USERNAME="$DESTINATION_USERNAME"
fi

git config --global user.email "$COMMIT_EMAIL"
git config --global user.name "$COMMIT_USERNAME"

# Remove git directory if it exists to prevent errors
rm -rf .git

A="A"
B="B"

echo "Cloning source and target repositories..."
git clone "https://$API_TOKEN_GITHUB@github.com/$GITHUB_REPOSITORY.git" $A
git clone --single-branch --branch "$DESTINATION_BRANCH" "https://$API_TOKEN_GITHUB@github.com/$DESTINATION_USERNAME/$DESTINATION_REPOSITORY.git" $B

default_user_email="$COMMIT_EMAIL"
default_user_name="$COMMIT_USERNAME"
sync_tag="#repo-missile"


# --- SCRIPT START ---

initialize_sync_on_repo_if_needed(){
    repo_folder="$1"
    repo_name="$2"

    (
    cd "$repo_folder" || exit 1

    last_sync_commit_hash=$(git log --grep="$sync_tag" -n 1 2>/dev/null)

    if [ -z "$last_sync_commit_hash" ]; then
        m="repo-missile: initial setup"
        git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
        git config user.name "github-actions[bot]"
        git commit --allow-empty -m "$m" -m "$sync_tag made in $repo_name" >/dev/null 2>&1

        #reset user config
        git config user.email "$default_user_email"
        git config user.name "$default_user_name"

        echo 1
    else
        echo 0
    fi
    )
}

push_action(){
    source_repo_folder="$1"
    target_repo_folder="$2"
    source_repo_name="$3"
    target_repo_name="$4"
    
    echo ""
    echo "source: $source_repo_folder"
    echo "target: $target_repo_folder"

    is_initial=0
    is_initial=$(initialize_sync_on_repo_if_needed "$source_repo_folder" "$source_repo_name")
    is_initial=$(initialize_sync_on_repo_if_needed "$target_repo_folder" "$source_repo_name")

    if [[ "$is_initial" -eq 1 ]]; then
        echo INITIAL SETUP COMPLETE
        return 0
    fi

    is_source_at_last_sync=0
    is_target_at_last_sync=0
    sync_tag="#repo-missile"

    is_source_at_last_sync=$( \
    repo_folder=$source_repo_folder
    cd "$repo_folder" || exit
    # check if the last commit has the sync tag. does not need to be subfolder when scope is implemented
    echo $(git log -1 --pretty=format:%B | grep -q "$sync_tag" && echo 1 || echo 0)
    )

    is_target_at_last_sync=$( \
    repo_folder=$target_repo_folder
    cd "$repo_folder" || exit
    # check if the last commit has the sync tag. does not need to be subfolder when scope is implemented
    echo $(git log -1 --pretty=format:%B | grep -q "$sync_tag" && echo 1 || echo 0)
    )

    if [[ "$is_source_at_last_sync" -eq 1 && "$is_target_at_last_sync" -eq 1 ]]; then
        echo "BOTH REPOS ALREADY IN SYNC"
        return 0
    fi
    
    if [[ "$is_source_at_last_sync" -eq 0 && "$is_target_at_last_sync" -eq 1 ]]; then
        echo "SOURCE REPO $source_repo_folder HAS MORE COMMITS"
        echo "giving commits to $target_repo_folder..."
        
        (
        cd "$source_repo_folder" || exit
        source_last_sync_commit_hash=$(git log --grep="$sync_tag" -n 1 --pretty=format:%H)
        mapfile -t commit_list < <(git log --reverse --oneline --pretty=format:%H "$source_last_sync_commit_hash"..HEAD)
        
        cd ..
        cd "$target_repo_folder" || exit

        git remote add temp_source "../$source_repo_folder"
        git fetch temp_source

        for commit_hash in "${commit_list[@]}"; do
            echo "Applying commit: $commit_hash"
        
            if ! git cherry-pick "$commit_hash"; then
                echo "ERROR: Cherry-pick failed for commit $commit_hash."
                echo "Aborting the cherry-pick and the script."
                git cherry-pick --abort
                git remote remove temp_source # Clean up before exiting
                exit 1
            fi
        done

        git remote remove temp_source
        )
        echo ""
        
    elif [[ "$is_source_at_last_sync" -eq 1 && "$is_target_at_last_sync" -eq 0 ]]; then
        echo "TARGET REPO $target_repo_folder HAS MORE COMMITS"
        echo "taking commits from $target_repo_folder..."
        echo "TODO: implement"
        echo ""
        
    else
        echo "BOTH REPOS HAVE NEWER COMMITS"
        echo "taking commits from $target_repo_folder..."
        echo "giving commits to $target_repo_folder..."
        echo "TODO: implement"
    fi

    echo "committing on both repos with $sync_tag for tracking..."
    # amend the last commit of both repos to include the sync tag. does not need to be subfolder when scope is implemented
    (
    cd "$target_repo_folder" || exit
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git config user.name "github-actions[bot]"
    git commit --allow-empty -m "repo-missile: take commits from $source_repo_name" -m "$sync_tag"

    #reset user config
    git config user.email "$default_user_email"
    git config user.name "$default_user_name"
    
    cd ..
    cd "$source_repo_folder" || exit
    git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
    git config user.name "github-actions[bot]"
    git commit --allow-empty -m "repo-missile: give commits to $target_repo_name" -m "$sync_tag"
    git config user.email "$default_user_email"
    git config user.name "$default_user_name"
    )
}

push_action $A $B "IMOaswell/A" "IMOaswell/B"