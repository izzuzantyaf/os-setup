{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.os-setup";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.sessionPath = [ "$HOME/.cargo/bin" ];
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    # the font everything renders in
    nerd-fonts.jetbrains-mono
    # one-word entry point for this repo: `zu rebuild`, `zu bootstrap`, `zu run`
    (writeShellScriptBin "zu" ''
      set -euo pipefail
      cd ~/.os-setup
      exec ./''${1:-rebuild}.sh "''${@:2}"
    '')
  ];
  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
      eval "$(fnm env --use-on-cd --shell zsh)"
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

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  # nvim writes lazy-lock.json here on plugin updates, so the whole dir is managed.
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  # The rest stay file-level: their dirs also hold state (zed conversations,
  # herdr logs, mole clean-list, mcp's .bak files) that must not land in the repo.
  home.file.".config/mcp/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/mcp/mcp.json";
  home.file.".config/zed/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/zed/settings.json";
  home.file.".config/herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr/config.toml";
  home.file.".config/mole/whitelist".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/mole/whitelist";

  # Pi coding agent: config files stay in this repo, ~/.pi/agent points at them.
  # auth.json, trust.json, sessions/, models-store.json, npm/ and herdr's
  # generated extension stay real on disk.
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

  # TypeSafe (Jev) decision skill: primitives, confidence bands, and the
  # keychain-backed caller script. Lives in .agents/skills so other harnesses
  # reading that tree get it too. No secret here; the key stays in the keychain.
  home.file.".agents/skills/typesafe".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/skills/typesafe";

  home.file.".gemini/GEMINI.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
