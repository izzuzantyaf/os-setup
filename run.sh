#!/bin/bash

echo '
1. Manjaro (GNOME)
2. Ubuntu (GNOME)
3. Ubuntu (WSL)
4. MacOS
Pilih salah satu : '
read num
if test $num = 1
then
  echo 'Installing Manjaro (GNOME) apps'
  cd ./manjaro/gnome
elif test $num = 2
then
  echo 'Installing Ubuntu (GNOME) apps'
  cd ./ubuntu/gnome
elif test $num = 3
then
  echo 'Installing Ubuntu (WSL) apps'
  cd ./ubuntu/wsl
elif test $num = 4
then
  echo 'MacOS setup is managed via Nix-Darwin.'
  echo 'Run ./bootstrap.sh for fresh setup or ./rebuild.sh to update.'
  exit
else
  echo 'Invalid input'
  exit
fi

bash ./install.sh
cd ../..
