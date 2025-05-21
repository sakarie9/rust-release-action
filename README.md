# Rust Release Action File Generator

This project provides a shell script (`generate.sh`) to bootstrap the necessary configuration files for setting up a release workflow for Rust projects using GoReleaser and GitHub Actions. It can optionally include Docker image building and publishing to GitHub Container Registry (GHCR).

## `generate.sh` Script

The `generate.sh` script automates the creation of:

- A GoReleaser configuration file (`.goreleaser.yaml`)
- A Dockerfile (optional)
- A GitHub Actions workflow file for releases (`release.yml`)

These files are generated based on templates and user-provided project details.

### Prerequisites

- Bash shell
- Standard Unix utilities like `sed`, `awk`, `cp`, `mkdir`.
- Template files must exist in a `templates/` directory relative to the script's location.

### Usage

```bash
./generate.sh <project_name> <repo_owner> <repo_name> [--no-docker]
```

**Arguments:**

- `<project_name>`: The name of your Rust project (e.g., `my-rust-app`). This will be used as the binary name and in other configurations.
- `<repo_owner>`: The GitHub username or organization that owns the repository where the Docker image will be published (e.g., `your-github-username`).
- `<repo_name>`: The name of the GitHub repository where the Docker image will be published (e.g., `my-rust-app`). This is often the same as `<project_name>`.
- `[--no-docker]` (Optional): If this flag is provided, Docker-related configurations will be removed from the generated `.goreleaser.yaml`, and the `Dockerfile` will not be generated.

### Template Files

The script expects the following template files to be present in a `templates/` directory:

- `templates/.goreleaser_template.yaml`: Template for GoReleaser configuration.
  - Placeholders: `##PROJECT_NAME##`, `##REPO_OWNER##`, `##REPO_NAME##`.
  - Docker section can be conditionally removed using `##DOCKER_START##` and `##DOCKER_END##` markers.
- `templates/Dockerfile_template`: Template for the Dockerfile.
  - Placeholder: `##PROJECT_NAME##`.
- `templates/release_template.yml`: Template for the GitHub Actions release workflow.

### Output Files

The script generates the following files in a `dist/` directory:

- `dist/.goreleaser.yaml`: The configured GoReleaser file.
- `dist/Dockerfile`: The configured Dockerfile (only if `--no-docker` is not specified).
- `dist/.github/workflows/release.yml`: The GitHub Actions workflow file.

After generation, you should review these files and then copy them to your project's root directory (and `.github/workflows/` for the workflow file) and commit them.

### `--no-docker` Option

If the `--no-docker` flag is used:

- The Docker-specific sections within `.goreleaser.yaml` (marked by `##DOCKER_START##` and `##DOCKER_END##`) will be removed.
- The `Dockerfile` will not be generated or copied to the `dist/` directory.

### Example

To generate files for a project named `my-cli-tool`, owned by `userX`, with the repository also named `my-cli-tool`, including Docker support:

```bash
./generate.sh my-cli-tool userX my-cli-tool
```

To generate files without Docker support:

```bash
./generate.sh my-cli-tool userX my-cli-tool --no-docker
```

This will create the necessary configuration files in the `dist/` directory.

Copy them to your rust project folder to use.

## Projects using this

- [sakarie9/pfs_rs](https://github.com/sakarie9/pfs_rs)
- [sakarie9/tg-stickerize](https://github.com/sakarie9/tg-stickerize)
