# Claude Code. Its own aspect (separate from `development`) since some
# hosts want the dev toolchain without it. Importing this is what turns it
# on for a host.
{...}: {
  flake.modules.homeManager.remote-ai = {
    config,
    pkgs,
    lib,
    ...
  }: let
    # Plugins to enable, as "<plugin>@<marketplace>". Claude Code installs any
    # enabled-but-missing plugin from its marketplace on next start.
    plugins = [
      "frontend-design@claude-plugins-official"
      "playwright@claude-plugins-official"
      "impeccable@impeccable"
      "caveman@caveman" # hooks need `node` on PATH — see home.packages

      # Code intelligence. These only launch the server; the binaries come
      # from lspServers below.
      "typescript-lsp@claude-plugins-official"
      "pyright-lsp@claude-plugins-official"
      "rust-analyzer-lsp@claude-plugins-official"
    ];

    # Language servers the LSP plugins above exec from PATH. Same packages
    # as modules/home/helix, so hosts with both share one store path.
    lspServers = with pkgs; [
      typescript-language-server # typescript-language-server
      typescript # tsserver, used by the above when a project has none
      pyright # pyright-langserver
      rust-analyzer # rust-analyzer
    ];

    # Marketplaces the plugins above come from (name → GitHub repo).
    marketplaces = {
      claude-plugins-official = "anthropics/claude-plugins-official";
      impeccable = "pbakaus/impeccable"; # https://github.com/pbakaus/impeccable
      caveman = "JuliusBrussee/caveman"; # https://github.com/JuliusBrussee/caveman
    };

    # Plugins whose `node` hooks get no network at all. Claude Code sets
    # CLAUDE_PLUGIN_ROOT (…/plugins/cache/<marketplace>/<plugin>/<ver>) when
    # it runs a plugin's hooks, so the `node` wrapper below can tell which
    # plugin is calling. Caveman's hooks only use fs/os/path today (its
    # telemetry lives in the separate `caveman` CLI, not installed here);
    # this keeps it that way even if an update adds network calls.
    offlinePlugins = ["caveman"];

    # `node` on PATH. For hooks of the plugins above it re-execs node inside
    # a fresh, unprivileged network namespace (only a downed loopback, so
    # every connect fails); everything else gets plain node.
    node = pkgs.writeShellScriptBin "node" ''
      case "''${CLAUDE_PLUGIN_ROOT:-}" in
        ${lib.concatMapStringsSep "|" (p: "*/${p}/*") offlinePlugins})
          exec ${pkgs.util-linux}/bin/unshare --user --map-current-user --net \
            ${pkgs.nodejs_22}/bin/node "$@" ;;
      esac
      exec ${pkgs.nodejs_22}/bin/node "$@"
    '';

    # PostToolUse hook: after Claude edits/writes a file, run that language's
    # formatter on just that file, so files stay in canonical form and Claude's
    # next old_string matches what's on disk. Formatters are pinned by store
    # path (no PATH dependency) and pick up project config (rustfmt.toml,
    # .prettierrc, pyproject.toml, …) on their own. Never blocks or fails the
    # edit: unknown types, generated paths and formatter errors are ignored.
    formatHook = pkgs.writeShellScript "claude-format-on-edit" ''
      f=$(${pkgs.jq}/bin/jq -r '.tool_input.file_path // empty')
      [ -f "$f" ] || exit 0
      case "$f" in
        */node_modules/*|*/target/*|*/.git/*|/nix/store/*|*-lock.json|*.lock) exit 0 ;;
      esac
      dir=$(dirname "$f")

      # rustfmt alone defaults to edition 2015; take it from the nearest
      # Cargo.toml that states one (skips `edition.workspace = true`).
      rust_edition() {
        d=$dir
        while [ "$d" != / ]; do
          if [ -f "$d/Cargo.toml" ]; then
            e=$(${pkgs.gnugrep}/bin/grep -m1 -oP '^\s*edition\s*=\s*"\K[0-9]+' "$d/Cargo.toml")
            [ -n "$e" ] && { echo "$e"; return; }
          fi
          d=$(dirname "$d")
        done
        echo 2021
      }

      case "$f" in
        *.rs) ${pkgs.rustfmt}/bin/rustfmt --edition "$(rust_edition)" "$f" ;;
        *.nix) ${pkgs.alejandra}/bin/alejandra -q "$f" ;;
        *.py|*.pyi) ${pkgs.ruff}/bin/ruff format -q "$f" ;;
        *.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs|*.json|*.jsonc|*.css|*.scss|*.html|*.vue|*.md)
          (cd "$dir" && ${pkgs.prettier}/bin/prettier --write --log-level silent "$f") ;;
        *.yaml|*.yml) ${pkgs.yamlfmt}/bin/yamlfmt "$f" ;;
        *.go) ${pkgs.go}/bin/gofmt -w "$f" ;;
        *.c|*.h|*.cc|*.cpp|*.hpp|*.cxx) ${pkgs.clang-tools}/bin/clang-format -i "$f" ;;
        *.sh|*.bash) ${pkgs.shfmt}/bin/shfmt -w "$f" ;;
        *.toml) ${pkgs.taplo}/bin/taplo fmt "$f" ;;
      esac >/dev/null 2>&1
      exit 0
    '';

    # Merged into ~/.claude/settings.json rather than owning the file:
    # Claude Code writes to settings.json itself (theme, /config changes,
    # plugin toggles), so a read-only store symlink would break it.
    managedSettings = pkgs.writeText "claude-managed-settings.json" (builtins.toJSON {
      enabledPlugins = lib.genAttrs plugins (_: true);
      extraKnownMarketplaces =
        lib.mapAttrs (_: repo: {
          source = {
            source = "github";
            inherit repo;
          };
        })
        marketplaces;
      # Caveman mode badge ([CAVEMAN], [ULTRACAVE], …). The caveman plugin
      # copies this script into ~/.claude/hooks/ on its first run; until
      # then the status line is just empty.
      statusLine = {
        type = "command";
        command = "bash \"${config.home.homeDirectory}/.claude/hooks/caveman-statusline.sh\"";
      };
      # Format-on-edit (formatHook above). Note the jq merge replaces arrays,
      # so any PostToolUse hooks added to settings.json by hand are dropped
      # on rebuild; add them here instead.
      hooks.PostToolUse = [
        {
          matcher = "Edit|MultiEdit|Write";
          hooks = [
            {
              type = "command";
              command = "${formatHook}";
              timeout = 30;
            }
          ];
        }
      ];
      # Claude Code's own telemetry (usage metrics) and error reporting.
      env = {
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
        DO_NOT_TRACK = "1";
      };
    });
  in {
    home.packages =
      lspServers
      ++ [
      pkgs.unstable.claude-code
      pkgs.sox # required by Claude Code's /voice mode for mic capture
      # caveman's hooks shell out to `node` and silently no-op without it.
      # The wrapper takes priority over bin/node from nodejs_22 below;
      # npm/npx still come from the real package.
      (lib.hiPrio node)
      pkgs.nodejs_22
    ];

    # Opt-out signal honoured by the caveman CLI and many other tools.
    home.sessionVariables.DO_NOT_TRACK = "1";
    systemd.user.sessionVariables.DO_NOT_TRACK = "1";

    # Deep-merge (jq `*`) so existing settings and any plugins enabled by
    # hand are kept; only the keys above are forced.
    home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      settings="$HOME/.claude/settings.json"
      run mkdir -p "$HOME/.claude"
      [ -s "$settings" ] || echo '{}' > "$settings"
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" ${managedSettings} > "$tmp" \
        && run mv "$tmp" "$settings"
    '';

    # Stops the periodic agent_summary side-query, which has no setting of its
    # own. Upstream and verification steps (re-run after Claude Code updates):
    # https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce
    home.sessionVariables.BUN_OPTIONS = "--preload=${./no-agent-summary.js}";
    systemd.user.sessionVariables.BUN_OPTIONS = "--preload=${./no-agent-summary.js}";
  };
}
