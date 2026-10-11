# Kitty terminal, Firefox (with extensions), Chromium, Thunderbird, and the
# Stylix theming targets they share. Wanted by both the GNOME desktop and
# the Hyprland compositor — see modules/home/desktop.nix and
# modules/home/hyprland/default.nix, both of which import this aspect
# rather than duplicating it.
{...}: {
  flake.modules.homeManager.desktop-apps = {
    pkgs,
    lib,
    inputs,
    ...
  }: {
    # ── Stylix theming targets ──────────────────────────────────────
    stylix.autoEnable = true;
    stylix.targets.zellij.enable = true;
    stylix.targets.bat.enable = true;

    programs.kitty = lib.mkForce {
      enable = true;
      settings = {
        confirm_os_window_close = 0;
        dynamic_background_opacity = true;
        enable_audio_bell = false;
        mouse_hide_wait = "-1.0";
        window_padding_width = 1; # Because Zellij adds padding.
        background_opacity = "0.9";
        background_blur = 5;
        symbol_map = let
          mappings = [
            "U+23FB-U+23FE"
            "U+2B58"
            "U+E200-U+E2A9"
            "U+E0A0-U+E0A3"
            "U+E0B0-U+E0BF"
            "U+E0C0-U+E0C8"
            "U+E0CC-U+E0CF"
            "U+E0D0-U+E0D2"
            "U+E0D4"
            "U+E700-U+E7C5"
            "U+F000-U+F2E0"
            "U+2665"
            "U+26A1"
            "U+F400-U+F4A8"
            "U+F67C"
            "U+E000-U+E00A"
            "U+F300-U+F313"
            "U+E5FA-U+E62B"
          ];
        in
          (builtins.concatStringsSep "," mappings) + " Symbols Nerd Font";
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
          order = ["ddg"];
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

    stylix.targets.firefox = {
      enable = true;
      colorTheme.enable = true;
      profileNames = ["default"];
    };

    programs.chromium.enable = true;

    programs.thunderbird.enable = true;
  };
}
