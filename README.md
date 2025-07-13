# repo-missile
A fork of [github-action-push-to-another-repository](https://github.com/cpina/github-action-push-to-another-repository) 

> [!NOTE]
> uses code from [danmindru's](https://github.com/danmindru/push-files-to-another-repository) <br>
> which is a fork of [nkoppel's](https://github.com/nkoppel/push-files-to-another-repository) <br>
> which is a fork of [cpina's](https://github.com/cpina/github-action-push-to-another-repository)

<br><br>

> [!CAUTION]
> the development of this project has been stopped. continuation will be done in [commit-catcher](https://github.com/IMOitself/commit-catcher). <br><br>
> **REASON:** just like [AfterReadme](https://github.com/IMOitself/AfterReadme) it is not working as intended and has fundamental flaw in the system. i really did tried coming up with different ideas how to implement it but it lead me to burnout oof!<br>

> [!WARNING]
> **this is a note if you really really really wanna try this** <br><br> there's no need to change `IMOitself/repo-missile@0.2` <br> at the code below. it is set to a stable release <br><br> do not change it to `IMOitself/repo-missile@master` <br> as it is currently unstable.

<br>

## TODO
- [ ] refactor entrypoint.sh
- [ ] make it not squash commits on push

## Installation 
> [!IMPORTANT]
> sadly discontinued ;-;<br><br>
> [*(outdated guide)*](https://github.com/danmindru/push-files-to-another-repository/blob/master/README.md)

## Example usage
- **Example Repositories:**
- [IMOaswell/A](https://github.com/IMOaswell/A) and [IMOaswell/B](https://github.com/IMOaswell/B)
- **Example workflow file:**
- ```yaml
    name: Sync Subfolder to Repo B

    on:
      push:
        branches:
          - master
        paths:
          - 'this/is/subfolder/**'

    jobs:
      push_subfolder_to_repo_b:
        runs-on: ubuntu-latest
        
        steps:
          - name: Checkout Repository A
            uses: actions/checkout@v4

          - name: Push 'this/is/subfolder' to Repository B
            uses: IMOitself/repo-missile@0.2
            env:
              API_TOKEN_GITHUB: ${{ secrets.GH_PAT }}
            with:
              source-files: 'this/is/subfolder/'
              destination-username: 'IMOaswell'
              destination-repository: 'B'
              destination-directory: 'this/is/subfolder'
              commit-email: 'IMOaswell@users.noreply.github.com'
  ```
