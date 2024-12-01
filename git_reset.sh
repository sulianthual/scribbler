#!/bin/bash

echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
echo "GIT RESET:" 
echo "this script will reset uncommited changes"
echo "(git reset, git checkout ., get clean -dfx)"
read -p "Confirm reset by entering yesido:" yesconfirm
if [ "$yesconfirm" != "yesido" ]; then
    echo "Did not confirm, Aborting"
    exit 1
fi

git reset
git checkout .
git clean -fdx
