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
    cd "$repo_folder" || exit
    pwd

    last_sync_commit_hash=$(git log --grep="#repo-missile" -1 --pretty=format:%H)
    if [ -z "$last_sync_commit_hash" ]; then
        echo ""
        echo "last sync commit not found."
        echo "probably because it is not initialized yet."
        echo ""

        m="#repo-missile initial sync" 
        git commit --allow-empty -m "$m" -m "made in $repo_name"
        git log --oneline
    fi
    )
}

push(){
    source_repo_folder="$1"
    target_repo_folder="$2"

    source_repo_name="IMOaswell/A"
    initialize_sync_on_repo_if_needed "$source_repo_folder" "$source_repo_name"
    initialize_sync_on_repo_if_needed "$target_repo_folder" "$source_repo_name"
}

push $A $B




# remove .git for repo-missile to not consider this directory as a submodule
cd $A && rm -rf .git
cd ..
cd $B && rm -rf .git
