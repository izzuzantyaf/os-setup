#!/bin/bash

### Note
# Before run these command below, run 'sudo su' first

echo -e "\n=== Installing My Daily Apps ==="

echo -e "\nInstalling CURL"
sudo apt -y install curl

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

#echo -e "\nInstalling Heroku CLI"
#curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

echo -e "\nInstalling PHP"
sudo apt -y install php

echo -e "\nInstalling Composer"
sudo apt -y install composer

echo -e "\nInstalling Node.js, NPM"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt update
sudo apt -y install nodejs
sudo apt -y install npm

echo -e "\nInstalling fnm"
curl -fsSL https://fnm.vercel.app/install | bash

echo -e "\nInstalling Yarn"
sudo npm install --global yarn

echo -e "\nInstalling pnpm"
sudo npm install -g pnpm

echo -e "\nInstalling Python"
sudo apt -y install python3

echo -e "\nInstalling Docker"
sudo apt-get -y remove docker docker-engine docker.io containerd runc
sudo apt-get -y update
sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker $USER
sudo docker run hello-world