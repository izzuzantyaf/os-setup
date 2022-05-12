#!/bin/bash

### Note
# Activate AUR and Flatpak in Add or Remove Software
# Before run these command below, run 'sudo su' first

echo -e "\n=== Installing My Daily Apps ==="

echo -e "\nInstalling Neofetch"
pamac install --no-confirm neofetch

echo -e "\nInstalling Git"
pamac install --no-confirm git

echo -e "\nInstalling PHP"
pamac install --no-confirm php

echo -e "\nInstalling Composer"
pamac install --no-confirm composer

echo -e "\nInstalling Yarn"
pamac install --no-confirm yarn

echo -e "\nInstalling Node.js, NPM"
pamac install --no-confirm nodejs npm

echo -e "\nInstalling Python"
pamac install --no-confirm python

echo -e "\nInstalling Github CLI"
pamac install --no-confirm github-cli

echo -e "\nInstalling Heroku CLI"
pamac install --no-confirm heroku-cli-bin

echo -e "\nInstalling Kvantum Manager"
pamac install --no-confirm kvantum

echo -e "\nInstalling Etcher"
pamac install --no-confirm etcher

echo -e "\nInstalling Shotwell"
pamac install --no-confirm shotwell

# echo -e "\nInstalling Microsoft Edge"
# pamac install --no-confirm microsoft-edge-stable-bin

# echo -e "\nInstalling  Firefox"
# pamac install --no-confirm firefox-appmenu-bin

echo -e "\nInstalling  Google Chrome"
pamac install --no-confirm google-chrome

# echo -e "\nInstalling  Onlyoffice"
# pamac install --no-confirm onlyoffice-desktopeditors

echo -e "\nInstalling Libreoffice"
pamac install --no-confirm libreoffice-fresh

echo -e "\nInstalling Visual Studio Code"
pamac install --no-confirm visual-studio-code-bin

echo -e "\nInstalling Responsively"
pamac install --no-confirm responsively

echo -e "\nInstalling Mongodb Compass"
pamac install --no-confirm mongodb-compass

echo -e "\nInstalling Postman"
pamac install --no-confirm postman-bin

echo -e "\nInstalling Spotify"
echo -e "If there's an issue when installing from CLI, install spotify from software center instead"
curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | gpg --import
pamac build --no-confirm spotify

echo -e "\nInstalling OBS Studio"
pamac install --no-confirm obs-studio

echo -e "\nInstalling Telegram"
pamac install --no-confirm telegram-desktop

echo -e "\nInstalling VLC Media"
pamac install --no-confirm vlc

echo -e "\nInstalling Audacity"
pamac install --no-confirm audacity

echo -e "\nInstalling GNU Image Processing"
pamac install --no-confirm gimp

# echo -e "\nInstalling Inkscape"
# pamac install --no-confirm inkscape

# echo -e "\nInstalling Kdenlive"
# pamac install --no-confirm kdenlive

# echo -e "\nInstalling Davinci Resolve"
# pamac install --no-confirm davinci-resolve

echo -e "\nInstalling Discord"
pamac install --no-confirm discord

echo -e "\nInstalling Zoom"
pamac install --no-confirm zoom

echo -e "\nInstalling Microsoft Teams"
pamac install --no-confirm teams
