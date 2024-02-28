#!/bin/bash

# Sets up variables
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
REPO_NAME="$1"
REPO_DIR="$2"
REPO_PRIVATE="TRUE"
REPO_SECRET=""

# Check if username and token is set in .bashrc || .bash_profile || .zshrc
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "Please set USERNAME and TOKEN in environment variables."
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
RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/user/repos -d "{\"name\":\"$REPO_NAME\", \"private\": $REPO_PRIVATE}")

# What authentication to use locally
while true; do
  read -p "Use SSH authentication? (y/n) " ssh
  case $ssh in
    [yY] ) REPO_URL=$(echo "$RESPONSE" | jq -r .ssh_url)
      REPO_SECRET=$REPO_URL
      break;;
    [nN] ) REPO_URL=$(echo "$RESPONSE" | jq -r .html_url) 
      # Insert the token into the URL
      REPO_SECRET="${REPO_URL:0:8}$GITHUB_USERNAME:$GITHUB_TOKEN@${REPO_URL:8}"
      break;;
  esac
done

# Check if the repository was successfully created
if [ "$REPO_URL" == "null" ]; then
  echo "Failed to create GitHub repository"
  echo "$RESPONSE"
  exit 1
fi

# Create project directory
if [ -z "$REPO_DIR" ]; then
  REPO_DIR="$HOME/dev"
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
git remote add origin "$REPO_SECRET"
git push -u origin main

echo "Repository created at $REPO_URL"
