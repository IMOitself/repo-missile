# Subfolder Sync Vibe

This repository contains a reusable GitHub Actions workflow to sync a subfolder between two repositories, preserving commit history.

## How it works

The `sync_script.sh` script uses `git format-patch` and `git am` to create patches for each commit in the source repository's subfolder and apply them to the destination repository. This preserves the original commit messages, authors, and timestamps.

## How to use

To use this reusable workflow, you need to create a workflow file in each of your repositories (e.g., `.github/workflows/sync.yml`). This workflow will call the reusable workflow in this repository.

### Example workflow

Here's an example of how to call the reusable workflow from your repository:

```yaml
name: Sync to B

on:
  push:
    branches:
      - main

jobs:
  sync:
    uses: your-username/subfoldersync-vibe/.github/workflows/sync.yml@main
    with:
      dest_repo: 'your-username/B'
      subfolder: 'this/is/subfolder'
    secrets:
      ssh_private_key: ${{ secrets.YOUR_SSH_PRIVATE_KEY }}
```

### Inputs

*   `dest_repo`: The destination repository to sync to.
*   `subfolder`: The subfolder to sync.

### Secrets

*   `YOUR_SSH_PRIVATE_KEY`: An SSH private key with write access to the destination repository.