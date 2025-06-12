#!/bin/bash

set -e

# Usage instructions
usage() {
  echo "Usage: $0 <project_name> <repo_owner> <repo_name> [--no-docker]"
  echo "  <project_name>: The name of the project (e.g., my-rust-app)"
  echo "  <repo_owner>: The owner/organization for the Docker image on GHCR (e.g., your-github-username)"
  echo "  <repo_name>: The name of the repository for the Docker image on GHCR (e.g., my-rust-app)"
  echo "  [--no-docker]: Optional. If provided, Docker-related configurations will be removed from .goreleaser.yaml"
  exit 1
}

# Initialize variables
PROJECT_NAME=""
REPO_OWNER=""
REPO_NAME=""
NO_DOCKER=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-docker) NO_DOCKER=true; shift ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME=$1
            elif [ -z "$REPO_OWNER" ]; then
                REPO_OWNER=$1
            elif [ -z "$REPO_NAME" ]; then
                REPO_NAME=$1
            else
                echo "Error: Unknown or too many arguments: $1"
                usage
            fi
            shift ;;
    esac
done

# Check required arguments
if [ -z "$PROJECT_NAME" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
  echo "Error: Missing required arguments."
  usage
fi

# Define template and output file paths
# Assumes this script is run from the project root and templates are in templates/
GORELEASER_TEMPLATE="templates/.goreleaser_template.yaml"
DOCKERFILE_TEMPLATE="templates/Dockerfile_template"
WORKFLOW_TEMPLATE="templates/release_template.yml"
CI_TEMPLATE="templates/ci_template.yml"

OUTPUT_DIR="dist"
OUTPUT_GORELEASER="${OUTPUT_DIR}/.goreleaser.yaml"
OUTPUT_DOCKERFILE="${OUTPUT_DIR}/Dockerfile"
OUTPUT_WORKFLOW="${OUTPUT_DIR}/.github/workflows/release.yml"
OUTPUT_CI="${OUTPUT_DIR}/.github/workflows/ci.yml"

# Check if template files exist
if [ ! -f "$GORELEASER_TEMPLATE" ]; then
  echo "Error: GoReleaser template not found at $GORELEASER_TEMPLATE"
  exit 1
fi

if [ ! -f "$DOCKERFILE_TEMPLATE" ]; then
  echo "Error: Dockerfile template not found at $DOCKERFILE_TEMPLATE"
  exit 1
fi

if [ ! -f "$WORKFLOW_TEMPLATE" ]; then
  echo "Error: Workflow template not found at $WORKFLOW_TEMPLATE"
  exit 1
fi

if [ ! -f "$CI_TEMPLATE" ]; then
  echo "Error: CI template not found at $CI_TEMPLATE"
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Generating files in $OUTPUT_DIR..."

# Process .goreleaser.yaml
echo "Processing $GORELEASER_TEMPLATE -> $OUTPUT_GORELEASER"
cp "$GORELEASER_TEMPLATE" "$OUTPUT_GORELEASER"
sed -i "s/##PROJECT_NAME##/${PROJECT_NAME}/g" "$OUTPUT_GORELEASER"
sed -i "s/##REPO_OWNER##/${REPO_OWNER}/g" "$OUTPUT_GORELEASER"
sed -i "s/##REPO_NAME##/${REPO_NAME}/g" "$OUTPUT_GORELEASER"

if [ "$NO_DOCKER" = true ]; then
  echo "Removing Docker configurations from $OUTPUT_GORELEASER..."
  # Use awk to delete content between ##DOCKER_START## and ##DOCKER_END## (inclusive)
  awk '
    /##DOCKER_START##/ { noprint=1 }
    !noprint { print }
    /##DOCKER_END##/ { noprint=0; next }
  ' "$OUTPUT_GORELEASER" > "${OUTPUT_GORELEASER}.tmp" && mv "${OUTPUT_GORELEASER}.tmp" "$OUTPUT_GORELEASER"
  # 也可以使用 sed，但对于多行删除，awk 通常更健壮
  # sed -i '/##DOCKER_START##/,/##DOCKER_END##/d' "$OUTPUT_GORELEASER"
fi

# Process Dockerfile
if [ "$NO_DOCKER" = false ]; then
  echo "Processing $DOCKERFILE_TEMPLATE -> $OUTPUT_DOCKERFILE"
  cp "$DOCKERFILE_TEMPLATE" "$OUTPUT_DOCKERFILE"
  sed -i "s/##PROJECT_NAME##/${PROJECT_NAME}/g" "$OUTPUT_DOCKERFILE"
else
  echo "Skipping Dockerfile generation as --no-docker was specified."
  if [ -f "$OUTPUT_DOCKERFILE" ]; then
    rm "$OUTPUT_DOCKERFILE"
  fi
fi

# Process GitHub Actions workflow
echo "Processing $WORKFLOW_TEMPLATE -> $OUTPUT_WORKFLOW"
mkdir -p "$(dirname "$OUTPUT_WORKFLOW")"
cp "$WORKFLOW_TEMPLATE" "$OUTPUT_WORKFLOW"
cp "$CI_TEMPLATE" "${OUTPUT_CI}"


echo "Generation complete."
echo "Generated files:"
echo "  $OUTPUT_WORKFLOW"
echo "  $OUTPUT_CI"
echo "  $OUTPUT_GORELEASER"
if [ "$NO_DOCKER" = false ] && [ -f "$OUTPUT_DOCKERFILE" ]; then
  echo "  $OUTPUT_DOCKERFILE"
fi
echo "Please review these files and then copy them to your project's root directory (and .github/workflows/ for the workflow) and commit them."

exit 0
