echo -e "\n=== Installing GNOME Shell Extensions ==="

echo -e "\nInstalling Night Theme Switcher"
pamac install --no-confirm gnome-shell-extension-nightthemeswitcher

echo -e "\nInstalling Just Perfection"
pamac install --no-confirm gnome-shell-extension-just-perfection-desktop

echo -e "\nInstalling Fildem Global Menu"
echo -e "Install manually from https://extensions.gnome.org/extension/4114/fildem-global-menu/"
pamac install --no-confirm python-fildem
pamac install --no-confirm gnome-session-properties

echo -e "\nInstalling Blur My Shell"
pamac install --no-confirm gnome-shell-extension-blur-my-shell

echo -e "\nInstalling Fix Top Panel Icon Spacing"
pamac install --no-confirm gnome-shell-extension-status-area-horizontal-spacing

echo -e "\nInstalling Add Username to Top Panel"
echo -e "Install manually from https://extensions.gnome.org/extension/1108/add-username-to-top-panel/"