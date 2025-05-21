#!/bin/bash

set -e

# 使用方法说明
usage() {
  echo "Usage: $0 <project_name> <repo_owner> <repo_name> [--no-docker]"
  echo "  <project_name>: The name of the project (e.g., my-rust-app)"
  echo "  <repo_owner>: The owner/organization for the Docker image on GHCR (e.g., your-github-username)"
  echo "  <repo_name>: The name of the repository for the Docker image on GHCR (e.g., my-rust-app)"
  echo "  [--no-docker]: Optional. If provided, Docker-related configurations will be removed from .goreleaser.yaml"
  exit 1
}

# 初始化变量
PROJECT_NAME=""
REPO_OWNER=""
REPO_NAME=""
NO_DOCKER=false

# 解析参数
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

# 检查必需的参数
if [ -z "$PROJECT_NAME" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
  echo "Error: Missing required arguments."
  usage
fi

# 定义模板文件和输出文件路径
# 假设此脚本在项目根目录运行，并且模板在 templates/ 目录下
GORELEASER_TEMPLATE="templates/.goreleaser_template.yaml"
DOCKERFILE_TEMPLATE="templates/Dockerfile_template"
WORKFLOW_TEMPLATE="templates/release_template.yml"

OUTPUT_DIR="dist"
OUTPUT_GORELEASER="${OUTPUT_DIR}/.goreleaser.yaml"
OUTPUT_DOCKERFILE="${OUTPUT_DIR}/Dockerfile"
OUTPUT_WORKFLOW="${OUTPUT_DIR}/.github/workflows/release.yml"

# 检查模板文件是否存在
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

# 创建输出目录（如果不存在）
mkdir -p "$OUTPUT_DIR"

echo "Generating files in $OUTPUT_DIR..."

# 处理 .goreleaser.yaml
echo "Processing $GORELEASER_TEMPLATE -> $OUTPUT_GORELEASER"
cp "$GORELEASER_TEMPLATE" "$OUTPUT_GORELEASER"
sed -i "s/##PROJECT_NAME##/${PROJECT_NAME}/g" "$OUTPUT_GORELEASER"
sed -i "s/##REPO_OWNER##/${REPO_OWNER}/g" "$OUTPUT_GORELEASER"
sed -i "s/##REPO_NAME##/${REPO_NAME}/g" "$OUTPUT_GORELEASER"

if [ "$NO_DOCKER" = true ]; then
  echo "Removing Docker configurations from $OUTPUT_GORELEASER..."
  # 使用 awk 删除 ##DOCKER_START## 和 ##DOCKER_END## 之间的内容（包括标记本身）
  awk '
    /##DOCKER_START##/ { noprint=1 }
    !noprint { print }
    /##DOCKER_END##/ { noprint=0; next }
  ' "$OUTPUT_GORELEASER" > "${OUTPUT_GORELEASER}.tmp" && mv "${OUTPUT_GORELEASER}.tmp" "$OUTPUT_GORELEASER"
  # 也可以使用 sed，但对于多行删除，awk 通常更健壮
  # sed -i '/##DOCKER_START##/,/##DOCKER_END##/d' "$OUTPUT_GORELEASER"
fi

# 处理 Dockerfile
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

# 处理 GitHub Actions 工作流
echo "Processing $WORKFLOW_TEMPLATE -> $OUTPUT_WORKFLOW"
mkdir -p "$(dirname "$OUTPUT_WORKFLOW")"
cp "$WORKFLOW_TEMPLATE" "$OUTPUT_WORKFLOW"


echo "Generation complete."
echo "Generated files:"
echo "  $OUTPUT_WORKFLOW"
echo "  $OUTPUT_GORELEASER"
if [ "$NO_DOCKER" = false ] && [ -f "$OUTPUT_DOCKERFILE" ]; then
  echo "  $OUTPUT_DOCKERFILE"
fi
echo "Please review these files and then copy them to your project's root directory and commit them."

exit 0
