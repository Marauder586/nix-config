# Hyprland Wayland compositor, Alacritty terminal, Firefox (with extensions),
# clipboard tools, and Stylix theming targets.
# Alacritty + Firefox: features.hyprland OR features.desktop
# Everything else: features.hyprland only
{
  pkgs,
  lib,
  inputs,
  features,
  ...
}: {
  config = lib.mkMerge [
    # ── Terminal + Browser (desktop or hyprland) ──────────────────────
    (lib.mkIf (features.hyprland || features.desktop) {
      # ── Stylix theming targets ──────────────────────────────────────
      stylix.autoEnable = true;
      stylix.targets.zellij.enable = true;
      stylix.targets.bat.enable = true;

      programs.alacritty = {
        enable = true;
        settings = {
          env.TERM = "xterm-256color";
          font.size = 12;
          scrolling.multiplier = 5;
          selection.save_to_clipboard = true;
        };
      };

      programs.firefox = {
        enable = true;
        profiles.default = {
          id = 0;
          name = "default";
          isDefault = true;
          settings = {
            "browser.search.defaultenginename" = "ddg";
            "browser.search.order.1" = "ddg";

            # ── Downloads ──────────────────────────────────────────────
            "browser.download.useDownloadDir" = false; # always ask where to save

            # ── Permissions: auto-deny notifications ───────────────────
            # 0 = always ask, 1 = allow, 2 = block
            "permissions.default.desktop-notification" = 2;

            # ── New tab page: search bar only ──────────────────────────
            "browser.newtabpage.activity-stream.feeds.topsites" = false;
            "browser.newtabpage.activity-stream.feeds.highlights" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
            "browser.newtabpage.activity-stream.feeds.discoverystreamfeed" = false;
            "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.default.sites" = "";
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;

            # ── Pocket ─────────────────────────────────────────────────
            "extensions.pocket.enabled" = false;

            # ── Address bar: no sponsored / Firefox Suggest junk ───────
            "browser.urlbar.quicksuggest.enabled" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
            "browser.urlbar.sponsoredTopSites" = false;
          };
          search = {
            force = true;
            default = "ddg";
            order = ["ddg" "google"];
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@np"];
              };
              "NixOS Wiki" = {
                urls = [{template = "https://nixos.wiki/index.php?search={searchTerms}";}];
                icon = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@nw"];
              };
              "bing".metaData.hidden = true;
              "google".metaData.alias = "@g";
            };
          };
          extensions = {
            force = true;
            packages = with inputs.firefox-addons.packages.${pkgs.system}; [
              bitwarden
              privacy-badger
              ublock-origin
              videospeed # Video Speed Controller — keyboard playback rate
            ];
          };
        };
      };

      programs.chromium.enable = true;

      stylix.targets.firefox = {
        enable = true;
        colorTheme.enable = true;
        profileNames = ["default"];
      };
    })

    # ── GNOME-only ────────────────────────────────────────────────────
    (lib.mkIf features.desktop {
      home.packages = with pkgs; [
        obsidian
        libreoffice
      ];

      dconf.settings."org/gnome/shell" = {
        favorite-apps =
          [
            "firefox.desktop"
            "Alacritty.desktop"
          ]
          ++ lib.optional features.communication "signal.desktop"
          ++ lib.optional features.communication "vesktop.desktop"
          ++ lib.optional features.gaming "steam.desktop"
          ++ ["org.gnome.Nautilus.desktop"];
      };
    })

    # ── Hyprland-only ─────────────────────────────────────────────────
    (lib.mkIf features.hyprland {
      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          "$mod" = "Alt_L";
          bind =
            [
              "$mod, ENTER, exec, alacritty"
            ]
            ++ (builtins.concatLists (
              builtins.genList (
                i: let
                  ws = i + 1;
                in [
                  "$mod, code:1${toString i}, workspace, ${toString ws}"
                  "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
                ]
              )
              9
            ));
        };
      };

      # ── DPI / cursor (4K monitor) ───────────────────────────────────
      xresources.properties = {
        "Xcursor.size" = 16;
        "Xft.dpi" = 172;
      };

      # ── Clipboard ──────────────────────────────────────────────────
      home.packages = with pkgs; [
        wl-clipboard
        xclip
      ];
    })
  ];
}
