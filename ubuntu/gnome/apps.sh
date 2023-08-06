#!/bin/bash

### Note
# Before run these command below, run 'sudo su' first

echo -e "\n=== Installing My Daily Apps ==="

mkdir packages

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

# echo -e "\nInstalling Heroku CLI"
# curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

echo -e "\nInstalling PHP"
sudo apt -y install php

echo -e "\nInstalling Composer"
sudo apt -y install composer

echo -e "\nInstalling Node.js, NPM"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt update
sudo apt-get install -y nodejs
sudo apt -y install npm

echo -e "\nInstalling fnm"
curl -fsSL https://fnm.vercel.app/install | bash

echo -e "\nInstalling Yarn"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt -y install yarn

echo -e "\nInstalling Python"
sudo apt -y install python3

echo -e "\nInstalling Etcher"
curl -1sLf \
   'https://dl.cloudsmith.io/public/balena/etcher/setup.deb.sh' \
   | sudo -E bash
sudo apt-get update
sudo apt-get -y install balena-etcher-electron

# echo -e "\nInstalling Microsoft Edge"
# curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
# sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
# sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-beta.list'
# sudo rm microsoft.gpg
# sudo apt update
# sudo -y apt install microsoft-edge-stable

# echo -e "\nInstalling  Firefox"
# sudo apt -y install firefox

echo -e "\nInstalling  Google Chrome"
wget -c -O ./packages/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt -y install ./packages/chrome.deb

echo -e "\nInstalling Libreoffice"
sudo apt -y install libreoffice

echo -e "\nInstalling Visual Studio Code"
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
sudo sudo apt -y install apt-transport-https
sudo apt update
sudo sudo apt -y install code # or code-insiders

echo -e "\nInstalling DBeaver"
wget -c -O ./packages/dbeaver-ce.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb
sudo apt -y install ./packages/dbeaver-ce.deb

echo -e "\nInstalling Postman"
# snap install postman
wget -c -O ./packages/postman.tar.gz https://dl.pstmn.io/download/latest/linux64
tar -xzf ./packages/postman.tar.gz
sudo rm -rf /opt/Postman
sudo mv Postman /opt/Postman
sudo ln -s /opt/Postman/Postman /usr/bin/postman
cd ../../..
cat > ./.local/share/applications/postman.desktop <<EOL
[Desktop Entry]
Encoding=UTF-8
Name=Postman
Exec=postman
# Before v6.1.2
# Icon=/opt/Postman/resources/app/assets/icon.png
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
EOL
cd os-setup/ubuntu/gnome

echo -e "\nInstalling OBS Studio"
sudo apt -y install obs-studio

echo -e "\nInstalling Telegram"
sudo apt -y install telegram-desktop

echo -e "\nInstalling VLC Media"
sudo apt -y install vlc

echo -e "\nInstalling Audacity"
sudo apt -y install audacity

echo -e "\nInstalling GNU Image Processing"
sudo apt -y install gimp

# echo -e "\nInstalling Inkscape"
# sudo apt -y install inkscape

# echo -e "\nInstalling Kdenlive"
# sudo apt -y install kdenlive

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

echo -e "\nInstalling Docker-based packages"
cd ../..
docker compose up -d --build
cd ubuntu/gnome

echo -e "\n"
echo -e "\nInstall the rest of the apps manually"
echo -e "\n1. Discord ==> https://discord.com/download"
echo -e "\n2. Zoom ==> https://zoom.us/download"
echo -e "\n3. Spotify ==> https://www.spotify.com/us/download/linux/"
echo -e "\n4. MongoDB Compass ==> https://www.mongodb.com/try/download/compass"
echo -e "\n5. Responsively ==> https://responsively.app/download"
echo -e "\n6. Termius ==> https://termius.com/download/linux"