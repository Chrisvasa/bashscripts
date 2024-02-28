#!/bin/bash

# Sets up variables
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
REPO_NAME="$1"
REPO_DIR="$2"
REPO_PRIVATE="TRUE"

# Check if username and token is set in .bashrc || .bash_profile || .zshrc
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "Please set USERNAME and TOKEN in environment variables."
  echo "For example, add the following lines to your ~/.bashrc, ~/.bash_profile, or ~/zshrc"
  echo "export GITHUB_USERNAME='username_here'"
  echo "export GITHUB_TOKEN='token_here'"
  exit 1;
fi

# Check if the repo name was provided
if [ -z "$REPO_NAME" ]; then
  echo "Usage: $0 <repo-name>"
  exit 1
fi

# Check that jq, curl and git are installed
command -v jq >/dev/null 2>&1 || { echo >&2 "Requires jq to be installed, aborting."; exit 1;}
command -v curl >/dev/null 2>&1 || { echo >&2 "Requires curl to be installed, aborting."; exit 1;}
command -v git >/dev/null 2>&1 || { echo >&2 "Requires git to be installed, aborting."; exit 1;}

# Ask for public/private repo
while true; do
  read -p "Private repo? (y/n) " private
  case $private in
    [yY] ) REPO_PRIVATE="true";
      break;;
    [nN] ) REPO_PRIVATE="false";
      break;;
  esac
done

# Create GitHub repository
RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" -d "{\"name\":\"$REPO_NAME\", \"private\": $REPO_PRIVATE}" https://api.github.com/user/repos)
REPO_URL=$(echo "$RESPONSE" | jq -r .ssh_url)

if [ "$REPO_URL" == "null" ]; then
  echo "Failed to create GitHub repository or extract URL."
  echo "$RESPONSE"
  exit 1
else
  echo "Repository created successfully: $REPO_URL"
fi

# Check if a REPO_DIR was given as parameter
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$HOME/dev"
fi

# Check if directory already exists or check if user wants to overwrite existing dir
if [ -d "$REPO_DIR/$REPO_NAME" ]; then
  read -p "Directory $REPO_DIR/$REPO_NAME already exists. Overwrite? (y/n) " overwrite
  case $overwrite in
  [yY] ) rm -rf "$REPO_DIR/$REPO_NAME";;
  [nN] ) echo "Using existing directory."; break;;
  * ) echo "Invalid option"; exit 1;;
  esac
fi

mkdir "$REPO_DIR/$REPO_NAME"
cd "$REPO_DIR/$REPO_NAME" || exit

# Initialize git and create basic files
git init
git checkout -b main
echo "# $REPO_NAME" > README.md
mkdir src include
touch src/.gitkeep
touch include/.gitkeep

# Add basic files to .gitignore
cat > .gitignore <<EOF
bin/
.vscode/
*.exe
EOF

# Add and commit changes
git add .
git commit -m "First commit"

# Add remote and push to GitHub
git remote add origin "$REPO_URL"
git push -u origin main

echo "Repository created at $REPO_URL"
