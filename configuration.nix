{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      AppleShowAllExtensions = true;
    };
    finder.FXPreferredViewStyle = "clmv";  # column view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    enableRosetta = true; # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    autoMigrate = true; # Automatically migrate existing Homebrew installations
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "node"
      "bun"
      "curl"
      "ffmpeg"
      "fnm"
      "go"
      "k6"
      "mole"
      "oh-my-posh"
      "ollama"
      "hermes-agent"
      "opencode"
      "php"
      "composer"
      "rtk"
      "rust"
      "rustup"
      "wget"
      "yarn"
      "yt-dlp"
      "mas"
    ];
    casks = [
      "antigravity-cli"
      "antigravity-ide"
      "audacity"
      "beekeeper-studio"
      "blip"
      "chatgpt"
      "cloudflare-warp"
      "codex"
      "codex-app"
      "cursor"
      "discord"
      "figma"
      "google-chrome"
      "google-drive"
      "google-gemini"
      "herd"
      "iina"
      "lm-studio"
      "microsoft-auto-update"
      "microsoft-teams"
      "obs"
      "obsidian"
      "ollama-app"
      "openvpn-connect"
      "orbstack"
      "protonvpn"
      "rapidapi"
      "tradingview"
      "visual-studio-code"
      "warp"
      "wezterm"
      "zed"
      "zen"
      "zoom"
    ];
  };
}
