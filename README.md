# repo-missile
A fork of [github-action-push-to-another-repository](https://github.com/cpina/github-action-push-to-another-repository) 

> [!NOTE]
> uses code from [danmindru's](https://github.com/danmindru/push-files-to-another-repository) <br>
> which is a fork of [nkoppel's](https://github.com/nkoppel/push-files-to-another-repository) <br>
> which is a fork of [cpina's](https://github.com/cpina/github-action-push-to-another-repository) 

## TODO
- [ ] refactor entrypoint.sh
- [ ] make it not squash commits on push

## Installation 
> [!IMPORTANT]
> comming soon..<br><br>
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
