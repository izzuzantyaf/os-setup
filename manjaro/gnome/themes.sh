#!/bin/bash

echo -e "\n=== Installing Themes ==="

echo -e "\nInstalling WhiteSur Theme"
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git ./themes/WhiteSur/gtk
cd ./themes/WhiteSur/gtk
./install.sh -s 220 -p 75 -i manjaro -P smaller -m --round
./tweaks.sh -d -f
cd ../../..

echo -e "\nInstalling WhiteSur Icons"
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git ./themes/WhiteSur/icons
cd ./themes/WhiteSur/icons
./install.sh -b
cd ../../..

echo -e "\nInstalling WhiteSur Cursors"
git clone https://github.com/vinceliuice/WhiteSur-cursors.git ./themes/WhiteSur/cursors
cd ./themes/WhiteSur/cursors
./install.sh
cd ../../..