#!/bin/bash

### Note
# Before run these command below, run 'sudo su' first

echo -e "\n=== Installing My Daily Apps ==="

echo -e "\nInstalling CURL"
sudo apt -y install curl

echo -e "\nInstalling RPM"
sudo apt -y install rpm

echo -e "\nInstalling Alien"
sudo apt -y install alien

echo -e "\nInstalling Neofetch"
sudo apt -y install neofetch

echo -e "\nInstalling Git"
sudo apt -y install git

echo -e "\nInstalling Github CLI"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo sudo apt -y install gh

echo -e "\nInstalling Heroku CLI"
curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

echo -e "\nInstalling PHP"
sudo apt -y install php

echo -e "\nInstalling Composer"
sudo apt -y install composer

echo -e "\nInstalling Node.js, NPM"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt update
sudo apt -y install nodejs
sudo apt -y install npm

echo -e "\nInstalling Yarn"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt -y install yarn

echo -e "\nInstalling Python"
sudo apt -y install python3

echo -e "\nInstalling MongoDB"
sudo apt -y install gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt -y install mongodb-org

