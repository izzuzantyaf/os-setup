# Headless sibling of home.nix for the Ubuntu VPS (Hetzner, root-only, 24.04).
# Managed with Home Manager standalone: no NixOS, the Ubuntu kernel and apt stay.
# Bootstrap a fresh box with ubuntu/vps/bootstrap.sh, update with ubuntu/vps/rebuild.sh.
{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.os-setup";
in

{
  # Non-NixOS Linux: sets up the env vars, ld paths and XDG dirs Nix expects.
  targets.genericLinux.enable = true;

  home.username = user;
  home.homeDirectory = if user == "root" then "/root" else "/home/${user}";
  home.stateVersion = "24.11";
  home.sessionPath = [ "$HOME/.cargo/bin" ];
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep fd fzf jq lazygit gh
    tmux btop rsync unzip  # tmux: no GUI on the VPS, so it's the terminal multiplexer
    # dev tools - the mac brews' nixpkgs twins
    ffmpeg
    go
    k6
    php
    phpPackages.composer
    wget
    curl
    yarn
    ghostscript
    # CPU-only build (nixpkgs default: no CUDA/ROCm). No service unit is
    # installed, so start it by hand: `ollama serve`.
    ollama
    yt-dlp
    neovim
    bun
    # rustup, not nixpkgs `rust`: rustup owns cargo/rustc, so a second
    # toolchain on PATH would shadow the shims. Run `rustup default stable` once.
    rustup
    fnm
    opencode
    rtk
    pi-coding-agent
    # no nixpkgs package for herdr, so this repo packages the release binary
    (callPackage ./pkgs/herdr.nix { })
    # one-word entry point for this repo: `zu rebuild` / `zu bootstrap` / `zu check`
    (writeShellScriptBin "zu" ''
      set -euo pipefail
      cd ~/.os-setup
      exec ./ubuntu/vps/''${1:-rebuild}.sh "''${@:2}"
    '')
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
      # fnm is a mac-side tool; the VPS has no node toolchain, so only load it if present.
      command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Izzu Z. Fawwas";
      email = "izzuzantyaf@gmail.com";
    };
  };

  # Edit-in-place: the real file stays in my repo, the home dir just points at it.
  # Same trick as home.nix. zed, wezterm, herdr and mole are mac-only and not here.
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/mcp/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/mcp/mcp.json";
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr/config.toml";

  # Pi coding agent: config files stay in this repo, ~/.pi/agent points at them.
  # auth.json, trust.json, sessions/ and models-store.json stay real on disk.
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/keybindings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/keybindings.json";
  home.file.".pi/agent/web-search.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/web-search.json";
  home.file.".pi/agent/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/AGENTS.md";
  home.file.".pi/agent/prompts".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/prompts";
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions/plan-mode".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions/plan-mode";
  home.file.".pi/agent/extensions/guard".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions/guard";
  home.file.".pi/agent/extensions/modes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions/modes";
  home.file.".pi/agent/extensions/big-pi-logo.ts".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions/big-pi-logo.ts";

  home.file.".agents/skills/typesafe".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/typesafe";

  home.file.".gemini/GEMINI.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
