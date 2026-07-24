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
      "com.apple.sound.beep.volume" = 0.7788008;  # ~75% alert volume
      "com.apple.sound.beep.feedback" = 0;        # no feedback on volume change
      "com.apple.trackpad.scaling" = 1.5;          # tracking speed (~40%)
      "com.apple.swipescrolldirection" = true;     # natural scrolling
      AppleEnableSwipeNavigateWithScrolls = true;  # two-finger swipe between pages
    };
    ".GlobalPreferences" = {
      "com.apple.sound.beep.sound" = "/System/Library/Sounds/Funk.aiff";  # alert sound
    };
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 60;  # 1 minute
    };
    loginwindow = {
      SHOWFULLNAME = false;       # show list of users
      ShutDownDisabled = false;
      SleepDisabled = false;
      RestartDisabled = false;
    };
    screencapture = {
      location = "~/Documents";
      type = "png";
      disable-shadow = false;
      include-date = true;
      save-selections = true;
      show-thumbnail = true;
      target = "file";
    };
    finder.FXPreferredViewStyle = "clmv";  # column view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad = {
      Clicking = true;                              # tap to click
      TrackpadRightClick = true;                    # two-finger click for right click
      FirstClickThreshold = 0;                      # light click
      ForceSuppressed = false;                      # force click enabled
      ActuateDetents = true;                        # haptic feedback
      TrackpadPinch = true;                         # pinch to zoom
      TrackpadTwoFingerDoubleTapGesture = true;     # smart zoom
      TrackpadRotate = true;                        # two-finger rotation
      TrackpadFourFingerHorizSwipeGesture = 2;      # four-finger swipe between full-screen apps
      TrackpadTwoFingerFromRightEdgeSwipeGesture = 3;  # two-finger swipe for Notification Center
      TrackpadFourFingerVertSwipeGesture = 2;       # four-finger swipe for Mission Control & App Exposé
      TrackpadFourFingerPinchGesture = 2;           # four-finger spread for Show Desktop
    };
    dock = {
      autohide = false;
      orientation = "bottom";
      mineffect = "genie";
      minimize-to-application = true;
      launchanim = true;
      show-process-indicators = true;
      show-recents = false;
      showAppExposeGestureEnabled = true;   # four-finger swipe down for App Exposé
      showMissionControlGestureEnabled = true;  # four-finger swipe up for Mission Control
      showDesktopGestureEnabled = true;     # four-finger spread for Show Desktop
      showLaunchpadGestureEnabled = false;  # four-finger pinch for Launchpad
      persistent-apps = [
        "/System/Applications/Mail.app"
        "/System/Applications/Notes.app"
        "/System/Applications/Reminders.app"
        "/Applications/Obsidian.app"
        "/Applications/Safari.app"
        "/Applications/Google Chrome.app"
        "/Applications/Microsoft Teams.app"
        "/Applications/Figma.app"
        "/Applications/WezTerm.app"
        "/Applications/Zed.app"
        "/Applications/Gemini.app"
        "/Applications/Claude.app"
        "/Applications/RapidAPI.app"
        "/System/Applications/Music.app"
        "/Users/${user}/Applications/YouTube.app"
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
