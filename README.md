# bashscripts


## Function to create a new project and cd into it
Add this to your .bashrc


```
function create() {
    /usr/bin/REPO.sh "$1" && cd "/home/user/dev/$1"
}
```
```
  echo "For example, add the following lines to your ~/.bashrc, ~/.bash_profile, or ~/zshrc"
  echo "export GITHUB_USERNAME='username_here'"
  echo "export GITHUB_TOKEN='token_here'"
```
