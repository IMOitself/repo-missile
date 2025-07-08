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

push(){
    source_repo_folder="$1"
    target_repo_folder="$2"

    source_repo_name="IMOaswell/A"
    is_initial=0
    is_initial=$(initialize_sync_on_repo_if_needed "$source_repo_folder" "$source_repo_name")
    is_initial=$(initialize_sync_on_repo_if_needed "$target_repo_folder" "$source_repo_name")

    if [[ "$is_initial" -eq 1 ]]; then
        echo INITIAL SETUP COMPLETE
        return 0
    fi

    (
    repo_folder=$source_repo_folder
    cd "$repo_folder" || exit
    last_commit_hash=$(git log -1 --pretty=format:%H)
    is_last_commit_synced=$(git log -1 --pretty=format:%B | grep -q "#repo-missile" && echo 1 || echo 0)

    if [[ "$is_last_commit_synced" -eq 1 ]]; then
        echo "$repo_folder SOURCE IS AT LAST SYNC"
    else
        echo "$repo_folder SOURCE IS NOT AT LAST SYNC"
    fi
    )

    (
    repo_folder=$target_repo_folder
    cd "$repo_folder" || exit
    last_commit_hash=$(git log -1 --pretty=format:%H)
    is_last_commit_synced=$(git log -1 --pretty=format:%B | grep -q "#repo-missile" && echo 1 || echo 0)

    if [[ "$is_last_commit_synced" -eq 1 ]]; then
        echo "$repo_folder TARGET IS AT LAST SYNC"
    else
        echo "$repo_folder TARGET IS NOT AT LAST SYNC"
    fi
    )
}



echo ""
echo simulates first time uploading the workflow file
push $A $B
push $B $A

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

cd ..
push $A $B
push $B $A
)

(
cd "$A" || exit
git log --oneline
cd ..
cd "$B" || exit
git log --oneline
)



# remove .git for repo-missile to not consider this directory as a submodule
cd $A && rm -rf .git
cd ..
cd $B && rm -rf .git
