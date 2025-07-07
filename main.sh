A="A"
B="B"

setup_folders() {
    F="$1"

    rm -rf "$F"
    mkdir "$F"

    cd "$F" || exit

    mkdir -p "subfolder"
    echo "$(date)" > hello.txt

    git config set advice.defaultBranchName false
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
