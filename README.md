# repo-missile
A fork of [cpina/github-action-push-to-another-repository](https://github.com/cpina/github-action-push-to-another-repository) 

> [!NOTE]
> uses code from [danmindru's](https://github.com/danmindru/push-files-to-another-repository) <br>
> which is a fork of [nkoppel's](https://github.com/nkoppel/push-files-to-another-repository) <br>
> which is a fork of [cpina/github-action-push-to-another-repository](https://github.com/cpina/github-action-push-to-another-repository) 

## TODO
- [ ] refactor entrypoint.sh
- [ ] make it not squash commits on push

## Inputs
### `source-files` (argument)
The files/directories to copy to the destination repository. Can have multiple space-separated filenames and globbing.

### `destination-username` (argument)
The name of the user or organization which owns the destination repository. E.g. `nkoppel`

### `destination-repository` (argument)
The name of the repository to copy files to, E.g. `push-files-to-another-repository`

### `destination-branch` (argument) [optional]
The branch name for the destination repository. Defaults to `master`.

### `destination-directory` (argument) [optional]
The directory in the destination repository to copy the source files into. Defaults to the destination project root.

### `commit-username` (argument) [optional]
The username to use for the commit in the destination repository. Defaults to `destination-username`

### `commit-email` (argument)
The email to use for the commit in the destination repository.

### `commit-message` (argument) [optional]
The commit message to be used in the output repository. Defaults to "Update from [destination url]@[commit]".

The string `ORIGIN_COMMIT` is replaced by `[destination url]@[commit]`.

### `API_TOKEN_GITHUB` (environment)
The GitHub API token which allows this action to push to the destination repository.

While GitHub Actions provide access tokens to workflows, there is no way to give them access to repositories outside of the one that the workflow is being run for, to my knowledge. Therefore, you need to generate a personal access token associated with your account. The token can be generated as either a fine-grained token or a classic personal access token. I recommend the fine-grained token, as you can restrict it to only be able to write to certain repositories, making them less useful to hackers if stolen.

To generate a fine-grained personal access token (recommended):
* Go to <https://github.com/settings/personal-access-tokens/new> or navigate to it through GitHub Settings > Developer Settings > Fine-grained tokens > Generate new token
* Fill out owner, name, and expiration date.
* Set "Repository Access" to "Only select repositories", and select the repositories you would like this action to be able to edit. Alternatively, select "All Repositories" to give it access to all of your repositories, at the cost of security.
* Click into "Repository Permissions" and set "Contents" to "Read and Write"
* Generate and copy the token.

To generate a classic personal access token (not recommended):
* Go to <https://github.com/settings/tokens/new> or navigate to it through GitHub Settings > Developer Settings > Personal Access Tokens > Tokens (classic) > Generate new token (classic)
* Name the token, enable only "repo" permissions, and copy it to your clipboard.
* Keep this token a secret, because anyone who has it can create commits in your repositories!

Then make the token available to the GitHub Action following the steps:
* Go to the GitHub page for the repository that you push from and click into "Settings"
* On the left sidebar, click into Secrets and Variables > Actions
* Click on "New Repository Secrets", name it "API_TOKEN_GITHUB", and paste your token.

## Example usage
- [IMOaswell/A](https://github.com/IMOaswell/A) and [IMOaswell/B](https://github.com/IMOaswell/B)
```yaml
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
        if: github.actor != 'github-actions[bot]'

        steps:
          - name: Checkout Repository A
            uses: actions/checkout@v4

          - name: Push 'this/is/subfolder' to Repository B
            uses: IMOitself/repo-missile@master
            env:
              API_TOKEN_GITHUB: ${{ secrets.GH_PAT }}
            with:
              source-files: 'this/is/subfolder/'
              destination-username: 'IMOaswell'
              destination-repository: 'B'
              destination-directory: 'this/is/subfolder'
              commit-email: 'IMOaswell@users.noreply.github.com'
```
