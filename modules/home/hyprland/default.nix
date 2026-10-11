# Hyprland Wayland compositor: keybinds, autostart, and the surrounding
# waybar / mako / wofi / hypridle / hyprlock / hyprpaper / cliphist stack.
#
# Importing this is what turns the Hyprland home-manager config on for a
# host — also import modules/home/desktop-apps.nix (kitty/firefox/chromium/
# thunderbird) alongside it; that's a peer aspect, not pulled in
# transitively, so a host importing *both* hyprland and desktop (which also
# wants desktop-apps) doesn't hit a diamond import. System-level enablement
# (portal, polkit, PAM) lives in modules/nixos/hyprland.nix — this module is
# the user-facing half.
{...}: {
  flake.modules.homeManager.hyprland = {pkgs, ...}: {
    # ── Stylix theming targets ──────────────────────────────────────────
    # stylix.autoEnable is already true (see modules/home/desktop-apps.nix),
    # so these would enable themselves regardless — declared explicitly to
    # match this repo's convention (see stylix.targets.firefox/zellij/bat)
    # and to keep working if autoEnable is ever flipped off.
    # stylix.targets.hyprland also auto-enables stylix.targets.hyprland.hyprpaper
    # (and therefore services.hyprpaper) whenever stylix.image != null, which
    # is how the wallpaper actually gets set — see hosts/mochi-guest.nix for
    # the stylix.image assignment.
    stylix.targets.hyprland.enable = true;
    stylix.targets.waybar.enable = true;
    stylix.targets.mako.enable = true;
    stylix.targets.wofi.enable = true;
    stylix.targets.hyprlock.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;

      # Hyprland itself is installed once, system-wide, by
      # modules/nixos/hyprland.nix (`programs.hyprland.enable`). Nulling these
      # out here avoids building/installing a second copy of Hyprland and the
      # portal via home-manager — this is the pairing the module's own option
      # docs recommend for exactly this NixOS + home-manager setup.
      package = null;
      portalPackage = null;

      # Home Manager 26.05 changed the default `configType` to "lua" (a very
      # different, much newer config DSL) for configs whose home.stateVersion
      # is >= 26.05, which this repo's is. Pin the traditional "hyprlang"
      # format explicitly: it's what `settings` below is written for, what
      # the vast majority of Hyprland documentation/examples still use, and
      # what this repo's stylix hyprland target itself special-cases as the
      # simpler branch.
      configType = "hyprlang";

      settings = let
        # Workspaces 1-9: bind by physical keycode (evdev 10-18 = the number
        # row 1-9 on any layout) rather than by character, so the bind is
        # layout-independent. Generates both the workspace-switch and
        # move-window-to-workspace binds for each of the 9 keys.
        workspaceBinds =
          builtins.concatLists (
            builtins.genList (
              i: let
                ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9
          );
      in {
        "$mod" = "Alt_L"; # Kept as Alt_L (not SUPER): this host also runs
        # GNOME on the same session-switcher (GDM), and GNOME leans heavily
        # on the Super key for its own overview/shortcuts — staying off Super
        # avoids muscle-memory collisions when hopping between the two.

        monitor = [",preferred,auto,auto"]; # No hardware-specific monitor
        # names to verify from here — falls back to Hyprland's own
        # auto-detected preferred mode/position/scale.

        env = [
          "XCURSOR_SIZE,16"
          "HYPRCURSOR_SIZE,16"
        ]; # Matches the Xcursor.size = 16 set for XWayland below, so cursor
        # size is consistent between native Wayland and XWayland clients.

        exec-once = [
          "mako" # Notification daemon — no systemd integration of its own,
          # so it needs starting explicitly (unlike waybar/hypridle/
          # hyprpaper/cliphist below, which register their own systemd user
          # services bound to Hyprland's session target).
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        ];

        general = {
          gaps_in = 4;
          gaps_out = 8;
          border_size = 2;
          layout = "dwindle";
          resize_on_border = true;
          # col.active_border / col.inactive_border are left unset here —
          # stylix.targets.hyprland supplies those from the active base16
          # scheme.
        };

        decoration = {
          rounding = 8;
          active_opacity = 1.0;
          inactive_opacity = 0.95;
          blur = {
            enabled = true;
            size = 4;
            passes = 2;
          };
          # decoration.shadow.color likewise comes from the stylix target.
        };

        animations = {
          enabled = true;
          bezier = "easeOutQuint, 0.23, 1, 0.32, 1";
          animation = [
            "windows, 1, 4, easeOutQuint"
            "windowsOut, 1, 4, easeOutQuint, popin 80%"
            "border, 1, 8, default"
            "fade, 1, 4, default"
            "workspaces, 1, 4, easeOutQuint"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        gestures.workspace_swipe = true;

        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad.natural_scroll = true;
        };

        # Float rules for the two GUI dialogs this Hyprland setup itself
        # brings in — the GTK file-picker portal and the polkit agent — so
        # they pop up as normal dialogs instead of getting tiled.
        windowrulev2 = [
          "float, class:^(xdg-desktop-portal-gtk)$"
          "float, class:^(Polkit-gnome-authentication-agent-1)$"
        ];

        bind =
          [
            # ── Apps ──────────────────────────────────────────────────
            "$mod, Q, exec, kitty"
            "$mod, R, exec, wofi --show drun -i"

            # ── Window management ────────────────────────────────────
            "$mod, C, killactive,"
            "$mod SHIFT, C, forcekillactive,"
            "$mod, M, exit,"
            "$mod, V, togglefloating,"
            "$mod, F, fullscreen, 0"
            "$mod, P, pseudo,"
            "$mod, J, togglesplit,"

            # ── Focus movement ────────────────────────────────────────
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"

            # ── Window movement ───────────────────────────────────────
            "$mod SHIFT, left, movewindow, l"
            "$mod SHIFT, right, movewindow, r"
            "$mod SHIFT, up, movewindow, u"
            "$mod SHIFT, down, movewindow, d"

            # ── Scroll through workspaces ─────────────────────────────
            "$mod, mouse_down, workspace, e+1"
            "$mod, mouse_up, workspace, e-1"

            # ── Clipboard history (cliphist, see services.cliphist below) ─
            "$mod SHIFT, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

            # ── Screenshots (grim + slurp; swappy for annotate, wl-copy
            #    straight to clipboard) ──────────────────────────────────
            ", Print, exec, grim - | swappy -f -"
            "$mod, Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
            "$mod SHIFT, Print, exec, grim -g \"$(slurp)\" - | wl-copy"

            # ── Lock ──────────────────────────────────────────────────
            "$mod, L, exec, hyprlock"
          ]
          ++ workspaceBinds;

        # Mouse move/resize.
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        # Media keys — work even when the session is locked (bindl), volume
        # ones also repeat while held (bindel).
        bindel = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
          ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ];
        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioStop, exec, playerctl stop"
        ];
      };
    };

    # ── DPI / cursor (4K monitor) ─────────────────────────────────────────
    xresources.properties = {
      "Xcursor.size" = 16;
      "Xft.dpi" = 172;
    };

    # ── Status bar ────────────────────────────────────────────────────────
    programs.waybar = {
      enable = true;
      systemd.enable = true; # Start/restart via Hyprland's own session
      # target instead of exec-once — consistent with hypridle/hyprpaper/
      # cliphist below.
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 32;
          modules-left = ["hyprland/workspaces" "hyprland/window"];
          modules-center = ["clock"];
          modules-right = ["pulseaudio" "network" "tray"];

          "hyprland/workspaces" = {
            on-click = "activate";
          };
          clock = {
            format = "{:%H:%M  %a %d %b}";
            tooltip-format = "{:%Y-%m-%d %H:%M}";
          };
          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "muted";
            format-icons = {
              default = ["" "" ""];
            };
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          };
          network = {
            format-wifi = "{essid} ({signalStrength}%)";
            format-ethernet = "eth";
            format-disconnected = "disconnected";
          };
          tray.spacing = 10;
        };
      };
    };

    # ── Notifications ─────────────────────────────────────────────────────
    # mako over the Hyprland-project's own agent stack for the same reason as
    # the polkit agent choice: it's small, dependency-light, and Wayland/
    # layer-shell native — no GTK4/libadwaita or Qt pull-in.
    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        default-timeout = 5000;
        border-radius = 8;
        border-size = 2;
        width = 320;
        margin = "10";
      };
    };

    # ── Idle / lock ────────────────────────────────────────────────────────
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = 900;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };

    programs.hyprlock = {
      enable = true;
      settings.general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        # background / input-field colors come from stylix.targets.hyprlock.
      };
    };

    # ── Wallpaper ──────────────────────────────────────────────────────────
    # No explicit hyprpaper config here — stylix.targets.hyprland.hyprpaper
    # (enabled above) points services.hyprpaper straight at stylix.image, the
    # same wallpaper set for GNOME (see hosts/mochi-guest.nix).

    # ── App launcher ───────────────────────────────────────────────────────
    programs.wofi = {
      enable = true;
      settings = {
        width = 600;
        height = 400;
        location = "center";
        show = "drun";
        allow_images = true;
        prompt = "";
      };
    };

    # ── Clipboard ──────────────────────────────────────────────────────────
    services.cliphist.enable = true; # History (bound to $mod SHIFT, V above).
    home.packages = with pkgs; [
      wl-clipboard
      xclip

      # Screenshots
      grim
      slurp
      swappy

      # Media / brightness keys
      brightnessctl
      playerctl

      # Polkit auth agent (see modules/nixos/hyprland.nix for the reasoning)
      polkit_gnome
    ];
  };
}
