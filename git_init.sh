#!/bin/bash

# Code for initializing github repository

echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo "GIT INIT AND PUSH:" 
echo "1) create empty repository on github"
echo "2) perform initial init and push with this script"
# Check if the directory is already a Git repository
if [ -d ".git" ]; then
    echo "folder .git found, Aborting (delete .git manually and restart)."
    exit 1
fi

read -p "Enter repository name: " reponame
if [ "$reponame" = "" ]; then
    echo "Empty repository name, Aborting"
    exit 1
fi

if [ ! -f /tmp/README.md ]; then
    echo '<!-- ![alt text](game_icon.png?raw=true "Screenshot") -->' > README.md
    echo "">>README.md
    echo "<h4>$reponame</h4>" >> README.md
    echo "">>README.md
    echo "sul ($(date +%Y), Godot 4 or above)" >> README.md
    echo "">>README.md
    echo "...">>README.md
    echo "">>README.md
    echo "Github reference: [link](https://github.com/sulianthual/$reponame)" >> README.md
fi

git init
git add -A
git commit -m "initial comit"

echo "XX"
echo "performed git init, add and commit"
echo "created generic README.md (unless already existing)"
read -p "Confirm add origin and push by entering yesido:" yesconfirm
if [ "$yesconfirm" != "yesido" ]; then
    echo "Did not confirm, Aborting"
    exit 1
fi

echo "adding origin and pushing"
# git remote add origin https://github.com/sulianthual/$reponame.git
# git branch -M main
# git push -u origin master

git branch -M main
git remote add origin https://github.com/sulianthual/$reponame.git
git push -u origin main

echo "Operation Completed"




