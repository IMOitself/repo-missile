A="A"
B="B"
default_user_email="IMOitself@users.noreply.github.com"
default_user_name="IMOitself"
A_SUBFOLDER="subfolder"
B_SUBFOLDER="libs"

setup_folders() {
    F="$1"

    rm -rf "$F"
    mkdir "$F"

    cd "$F" || exit

    echo "fixed text right here. made in $F :D" > hello.txt

    git config --global --add safe.directory "$(pwd)"
    git init .
    git status

    git config init.defaultBranch "master"
    git config user.email "$default_user_email"
    git config user.name "$default_user_name"

    git add .
    git commit -m "initial commit"

    cd ..
}

setup_folders $A
setup_folders $B
(
cd "$A" || exit
mkdir "$A_SUBFOLDER"
cd ..
cd "$B" || exit
mkdir "$B_SUBFOLDER"
)

sync_tag="#repo-missile"

initialize_sync_on_repo_if_needed(){
    repo_folder="$1"
    repo_name="$2"
    subfolder_to_sync="$3"

    (
    cd "$repo_folder" || exit 1

    last_sync_commit_hash=$(git log --grep="$sync_tag" -n 1 2>/dev/null) # not really a commit hash

    if [ -z "$last_sync_commit_hash" ]; then
        git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
        git config user.name "github-actions[bot]"
        git commit --allow-empty -m "repo-missile: initial setup" -m "$sync_tag made in $repo_name" >/dev/null 2>&1

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
    source_subfolder_to_sync="$4"
    target_subfolder_to_sync="$5"
    
    echo ""
    echo "source: $source_repo_folder"
    echo "target: $target_repo_folder"

    is_initial=0
    is_initial=$(initialize_sync_on_repo_if_needed "$source_repo_folder" "$source_repo_name" "$source_subfolder_to_sync")
    is_initial=$(initialize_sync_on_repo_if_needed "$target_repo_folder" "$source_repo_name" "$target_subfolder_to_sync")

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

    result=$(git log -1 --pretty=format:%B -- "$source_subfolder_to_sync" 2>/dev/null | grep -q "$sync_tag" && echo 1 || echo 0)

    if [[ -z "$result" || "$result" -eq 0 ]]; then
        # check if the last commit that has a sync tag is not in the subfolder
        result=$(git log -1 --pretty=format:%B 2>/dev/null | grep -q "$sync_tag" && echo 1 || echo 0)
    fi
    echo $result
    )

    is_target_at_last_sync=$( \
    repo_folder=$target_repo_folder
    cd "$repo_folder" || exit
    
    result=$(git log -1 --pretty=format:%B -- "$target_subfolder_to_sync" 2>/dev/null | grep -q "$sync_tag" && echo 1 || echo 0)
    
    if [[ -z "$result" || "$result" -eq 0 ]]; then
        # check if the last commit that has a sync tag is not in the subfolder
        result=$(git log -1 --pretty=format:%B 2>/dev/null | grep -q "$sync_tag" && echo 1 || echo 0)
    fi
    echo $result
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
    mapfile -t commit_list < <(git log --reverse --pretty=format:%H "$source_last_sync_commit_hash"..HEAD -- "$source_subfolder_to_sync")

    cd ..
    cd "$target_repo_folder" || exit

    for commit_hash in "${commit_list[@]}"; do
        echo "Applying commit: $commit_hash"

        COMMIT_MSG=$(git --git-dir="../$source_repo_folder/.git" log --format=%B -n 1 "$commit_hash")
        COMMIT_AUTHOR=$(git --git-dir="../$source_repo_folder/.git" log --format="%an <%ae>" -n 1 "$commit_hash")
        COMMIT_DATE=$(git --git-dir="../$source_repo_folder/.git" log --format=%ad -n 1 "$commit_hash")

        git --git-dir="../$source_repo_folder/.git" diff "$commit_hash^..$commit_hash" -- "$source_subfolder_to_sync" | \
            sed -e "s| a/$source_subfolder_to_sync| a/$target_subfolder_to_sync|g" \
                -e "s| b/$source_subfolder_to_sync| b/$target_subfolder_to_sync|g" \
            > /tmp/commit.patch
        if git apply /tmp/commit.patch; then
            git add "$target_subfolder_to_sync"
            git commit --message="$COMMIT_MSG" --author="$COMMIT_AUTHOR" --date="$COMMIT_DATE"
        else
            echo "ERROR: Failed to apply patch for commit $commit_hash." >&2
            echo "Manual intervention required. Patch file saved at /tmp/commit.patch" >&2
            exit 1
        fi
        
        rm /tmp/commit.patch
    done
)
        echo ""
        
    elif [[ "$is_source_at_last_sync" -eq 1 && "$is_target_at_last_sync" -eq 0 ]]; then
        echo ""
        echo "ERROR: TARGET REPO $target_repo_folder HAS MORE COMMITS"
        echo "TODO: implement taking commits from $target_repo_folder"
        echo ""
        exit 1
        
    elif [[ "$is_source_at_last_sync" -eq 0 && "$is_target_at_last_sync" -eq 0 ]]; then
        echo ""
        echo "ERROR: both repos have newer commits"
        echo "TODO: implement taking commits from $target_repo_folder"
        echo "TODO: then implement giving commits to $target_repo_folder"
        echo ""
        exit 1
    else
        echo ""
        echo "ERROR: unknown state"
        echo "is_source_at_last_sync: $is_source_at_last_sync"
        echo "is_target_at_last_sync: $is_target_at_last_sync"
        echo ""
        exit 1
    fi

    echo "committing on both repos with $sync_tag for tracking..."
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

echo ""
echo "--- SIMULATIONS ---"
echo ""

echo ""
echo simulates first time uploading the workflow file
push_action $A $B "IMOaswell/A" "$A_SUBFOLDER" "$B_SUBFOLDER"
push_action $B $A "IMOaswell/B" "$B_SUBFOLDER" "$A_SUBFOLDER"

(
cd "$A" || exit
git log --oneline
cd ..
cd "$B" || exit
git log --oneline
)

echo ""
echo simulates repo A has more commits than repo B
(
cd "$A" || exit
echo "newly created file :D" > "$A_SUBFOLDER/hi.txt"

git add .
git commit -q -m "create $A_SUBFOLDER/hi.txt"

echo "not so fixed anymore :D" > "hello.txt"

git add .
git commit -q -m "a commit that is not for subfolder"

echo "hi there :D" > "$A_SUBFOLDER/hi.txt"
git add .
git commit -q -m "update $A_SUBFOLDER/hi.txt"
)

push_action $A $B "IMOaswell/A" "$A_SUBFOLDER" "$B_SUBFOLDER"

(
cd "$A" || exit
git log --oneline
cd ..
cd "$B" || exit
git log --oneline
)

push_action $B $A "IMOaswell/B" "$B_SUBFOLDER" "$A_SUBFOLDER"

echo ""
echo simulates repo B has more commits than repo A
(
cd "$B" || exit
echo "uwu :D" > "$B_SUBFOLDER/hi.txt"

git add .
git commit -q -m "update $B_SUBFOLDER/hi.txt again"

echo "hello there :D" > "hello.txt"
git add .
git commit -q -m "a commit that is not for subfolder"
)

push_action $B $A "IMOaswell/B" "$B_SUBFOLDER" "$A_SUBFOLDER"

(
cd "$A" || exit
git log --oneline
cd ..
cd "$B" || exit
git log --oneline
cd ..
)

push_action $A $B "IMOaswell/A" "$A_SUBFOLDER" "$B_SUBFOLDER"

# remove .git for repo-missile to not consider this directory as a submodule
cd $A && rm -rf .git
cd ..
cd $B && rm -rf .git
