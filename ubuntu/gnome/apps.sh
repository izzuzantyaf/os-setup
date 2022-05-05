#!/bin/bash

### Note
# Before run these command below, run 'sudo su' first

echo -e "\n=== Installing My Daily Apps ==="

mkdir packages

echo -e "\nInstalling Pacstall"
sudo bash -c "$(curl -fsSL https://git.io/JsADh || wget -q https://git.io/JsADh -O -)"

echo -e "\nInstalling deb-get"
curl -sL https://raw.githubusercontent.com/wimpysworld/deb-get/main/deb-get | sudo -E bash -s install deb-get

echo -e "\nInstalling Grub Customizer"
apt install grub-customizer

echo -e "\nInstalling RPM"
apt install rpm

echo -e "\nInstalling Alien"
apt install alien

echo -e "\nInstalling CURL"
apt install curl

echo -e "\nInstalling Neofetch"
apt install neofetch

echo -e "\nInstalling Git"
apt install git

echo -e "\nInstalling PHP"
apt install php

echo -e "\nInstalling Composer"
apt install composer

echo -e "\nInstalling Yarn"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install yarn

echo -e "\nInstalling Node.js, NPM"
apt install nodejs npm

echo -e "\nInstalling Python"
apt install python

echo -e "\nInstalling Github CLI"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

echo -e "\nInstalling Etcher"
pacstall -I balena-etcher-electron-deb

echo -e "\nInstalling Shotwell"
apt install shotwell

# echo -e "\nInstalling Microsoft Edge"
# pacstall -I microsoft-edge-stable-deb

# echo -e "\nInstalling  Firefox"
# apt install firefox

echo -e "\nInstalling  Google Chrome"
wget -c -O ./packages/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install ./packages/chrome.deb

echo -e "\nInstalling Libreoffice"
apt install libreoffice

echo -e "\nInstalling Visual Studio Code"
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo apt install apt-transport-https
sudo apt update
sudo apt install code # or code-insiders

echo -e "\nInstalling Responsively"
wget -c -O ./packages/responsively.rpm https://github.com/responsively-org/responsively-app/releases/download/v0.18.0/Responsively-App-0.18.0.x86_64.rpm
sudo rpm -i ./packages/responsively.rpm

echo -e "\nInstalling Mongodb Compass"
wget -c -O ./packages/mongodb-compass.deb https://downloads.mongodb.com/compass/mongodb-compass_1.31.1_amd64.deb
apt install ./packages/mongodb-compass.deb

echo -e "\nInstalling Postman"
snap install postman

echo -e "\nInstalling Spotify"
curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add - 
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt-get update && sudo apt-get install spotify-client

echo -e "\nInstalling OBS Studio"
apt install obs-studio

echo -e "\nInstalling Telegram"
apt install telegram-desktop

echo -e "\nInstalling VLC Media"
apt install vlc

echo -e "\nInstalling Audacity"
apt install audacity

echo -e "\nInstalling GNU Image Processing"
apt install gimp

# echo -e "\nInstalling Inkscape"
# apt install inkscape

# echo -e "\nInstalling Kdenlive"
# apt install kdenlive

echo -e "\nInstalling Discord"
deb-get install discord

echo -e "\nInstalling Zoom"
deb-get install zoom

echo -e "\nInstalling Microsoft Teams"
deb-get install teams
