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
      AppleInterfaceStyleSwitchesAutomatically = true;
    };
    finder.FXPreferredViewStyle = "clmv";  # column view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
    dock = {
      autohide = false;
      persistent-apps = [
        "/System/Applications/Finder.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Reminders.app"
        "/Applications/Obsidian.app"
        "/Applications/Safari.app"
        "/Applications/Google Chrome.app"
        "/Applications/Microsoft Teams.app"
        "/Applications/Figma.app"
        "/Applications/WezTerm.app"
        "/Applications/Zed.app"
        "/Applications/Antigravity IDE.app"
        "/Applications/Gemini.app"
        "/Applications/Claude.app"
        "/Applications/RapidAPI.app"
        "/System/Applications/Music.app"
        "/Users/${user}/Applications/Duolingo.app"
      ];
      persistent-others = [
        {
          folder = {
            path = "/Users/${user}/Downloads";
            displayas = "folder";
            showas = "fan";
            arrangement = "date-added";
          };
        }
      ];
    };
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
      "mlx-lm"
    ];
    casks = [
      "antigravity-cli"
      "antigravity-ide"
      "audacity"
      "beekeeper-studio"
      "blip"
      "cloudflare-warp"
      "codex"
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
