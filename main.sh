A="A"
B="B"

setup_folders() {
    F="$1"

    rm -rf "$F"
    mkdir "$F"

    cd "$F" || exit

    mkdir -p "subfolder"
    echo "fixed text right here :D" > hello.txt

    git config --global --add safe.directory "$(pwd)"
    git init .
    git status

    git config init.defaultBranch "master"
    git config user.email "IMOitself@users.github.com"
    git config user.name "IMOitself"

    git add .
    git commit -m "initial commit"

    cd ..
}

setup_folders $A
setup_folders $B

initialize_sync_on_repo_if_needed(){
    repo_folder="$1"
    repo_name="$2"

    (
    cd "$repo_folder" || exit 1

    last_sync_commit_hash=$(git log --grep="#repo-missile" -n 1 2>/dev/null)

    if [ -z "$last_sync_commit_hash" ]; then
        m="#repo-missile initial setup"
        git commit --allow-empty -m "$m" -m "made in $repo_name" >/dev/null 2>&1

        echo 1
    else
        echo 0
    fi
    )
}

push_action(){
    source_repo_folder="$1"
    target_repo_folder="$2"
    echo ""
    echo "source: $source_repo_folder"
    echo "target: $target_repo_folder"

    source_repo_name="IMOaswell/A"
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
        source_last_sync_commit_hash=$(git log --grep="#repo-missile" -n 1 --pretty=format:%H)
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

    echo "amending last commits of both repos with $sync_tag for tracking..."
    # amend the last commit of both repos to include the sync tag. does not need to be subfolder when scope is implemented
    (
    cd "$target_repo_folder" || exit
    git commit --amend -m "$(git log -1 --pretty=format:%B)" -m "$sync_tag"
    
    cd ..
    cd "$source_repo_folder" || exit
    git commit --amend -m "$(git log -1 --pretty=format:%B)" -m "$sync_tag"
    )
}



echo ""
echo simulates first time uploading the workflow file
push_action $A $B
push_action $B $A

(
cd "$A" || exit
git log --oneline
cd ..
cd "$B" || exit
git log --oneline
)

echo ""
echo simulates one repo A has more commits than repo B
(
cd "$A" || exit
echo "newly created file :D" > subfolder/hi.txt

git add .
git commit -m "create hi.txt"

echo "hi there :D" > subfolder/hi.txt
git add .
git commit -m "update hi.txt"
)

push_action $A $B

(
cd "$A" || exit
git log --oneline
cd ..
cd "$B" || exit
git log --oneline
)

push_action $B $A


# remove .git for repo-missile to not consider this directory as a submodule
cd $A && rm -rf .git
cd ..
cd $B && rm -rf .git
