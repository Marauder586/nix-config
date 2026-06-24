# Always-on user configuration.
# Git, shell (bash + zsh), and essential CLI tools that belong on every machine.
# All current hosts (mochi, mochi-guest, hm-foreign) enable Stylix, so this
# module reads `config.lib.stylix.colors` for the delta diff theme.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Linear-interpolate between two base16 hex strings (no leading #).
  # mixHex a b t  →  a when t=0, b when t=1.
  # Uses nix-colors' hexToRGB on the way in; lib.toHexString + zero-pad
  # on the way back. Round half-up via floor(x + 0.5).
  pad2 = s:
    if lib.stringLength s == 1
    then "0${s}"
    else s;
  toHex2 = n: pad2 (lib.toLower (lib.toHexString n));
  mixHex = a: b: t: let
    rgbA = inputs.nix-colors.lib.conversions.hexToRGB a;
    rgbB = inputs.nix-colors.lib.conversions.hexToRGB b;
    blend = i:
      builtins.floor (
        (1.0 - t)
        * (lib.elemAt rgbA i)
        + t * (lib.elemAt rgbB i)
        + 0.5
      );
  in "${toHex2 (blend 0)}${toHex2 (blend 1)}${toHex2 (blend 2)}";
in {
  home.sessionVariables = {
    EDITOR = "hx";
  };

  # ── Essential CLI tools ───────────────────────────────────
  home.packages = with pkgs; [
    nerd-fonts.iosevka
    fastfetch

    # Archives
    zip
    xz
    unzip
    zstd
    p7zip

    # Modern Unix replacements (GNU → Rust)
    eza # ls
    bat # cat  (programs.bat below manages config)
    fd # find
    ripgrep # grep
    sd # sed  (note: different syntax — use sd 'pat' 'repl' file)
    dust # du   (binary: dust)
    procs # ps
    bottom # top  (binary: btm)
    delta # git pager / diff prettifier
    choose # cut  (binary: choose)

    # Fuzzy finder + interactive tools
    fzf
    zoxide # smarter cd (programs.zoxide below manages shell init)

    # Core utilities
    tree
    which
    file
    gawk
    gnused
    gnutar
    gnupg

    # Structured data
    jq
    yq-go

    # Terminal multiplexer
    zellij

    # Nix tooling
    nix-output-monitor

    # Content / docs
    hugo
    glow
  ];

  # ── bat (cat replacement) ─────────────────────────────────
  # Stylix overrides the theme on NixOS hosts; Dracula is the fallback.
  programs.bat = {
    enable = true;
    config = {
      paging = "never";
      style = "plain";
    };
  };

  # ── zoxide (smarter cd) ───────────────────────────────────
  # Use `z <dir>` to jump, `zi` for interactive selection.
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # ── Shell aliases (all shells) ────────────────────────────
  # GNU util → Rust equivalent
  home.shellAliases = {
    ls = "eza --icons=auto --color=always --group-directories-first";
    ll = "eza -la --icons=auto --git --color=always --group-directories-first";
    la = "eza -a --icons=auto --color=always --group-directories-first";
    lt = "eza --tree --icons=auto --color=always";
    cat = "bat";
    find = "fd";
    grep = "rg";
    du = "dust";
    ps = "procs";
    top = "btm";
  };

  # ── Git ───────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "marauder";
        email = "njdeary@yahoo.com";
      };
      core = {
        editor = "hx";
        excludesfile = "~/.gitignore";
        pager = "delta";
      };
      interactive.diffFilter = "delta --color-only";
      delta = let
        c = config.lib.stylix.colors;
      in {
        navigate = true;
        side-by-side = true;
        line-numbers = true;

        # Diff line backgrounds: red (base08) / green (base0B) blended into
        # the scheme's base bg (base00) at 50% (line) and 70% (emph). This
        # is louder than the upstream Catppuccin recipe (20% / 35%) — closer
        # to the classic git-diff feel — but stays scheme-agnostic, so
        # swapping stylix.base16Scheme retints the diff. Foreground stays
        # `syntax` so bat-coloured code keeps its tones. Gutter line numbers
        # use the pure base08 / base0B accents.
        minus-style = "syntax \"#${mixHex c.base00 c.base08 0.35}\"";
        minus-emph-style = "bold syntax \"#${mixHex c.base00 c.base08 0.50}\"";
        plus-style = "syntax \"#${mixHex c.base00 c.base0B 0.35}\"";
        plus-emph-style = "bold syntax \"#${mixHex c.base00 c.base0B 0.50}\"";
        line-numbers-minus-style = "bold \"#${c.base08}\"";
        line-numbers-plus-style = "bold \"#${c.base0B}\"";
      };
      column.ui = "auto";
      init.defaultBranch = "main";
      push = {
        default = "simple";
        autoSetupRemote = true;
        followTags = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
      help.autocorrect = "prompt";
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      rebase = {
        autoSquash = true;
        autoStash = true;
        updateRefs = true;
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
  };

  # ── Bash ──────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';
    shellAliases = {
      k = "kubectl";
      shx = "sudoedit";
      urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
    };
  };

  # ── Zsh ───────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = ["git"];
      theme = "nicoulaj";
    };
    shellAliases = {
      k = "kubectl";
      shx = "sudoedit";
    };
    initContent = ''
      eval "$(zellij setup --generate-auto-start zsh)"
    '';
  };
}
