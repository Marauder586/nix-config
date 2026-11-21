# Claude Code. Its own aspect (separate from `development`) since some
# hosts want the dev toolchain without it. Importing this is what turns it
# on for a host.
{...}: {
  flake.modules.homeManager.remote-ai = {pkgs, ...}: {
    home.packages = [
      pkgs.unstable.claude-code
      pkgs.sox # required by Claude Code's /voice mode for mic capture
    ];

    # Stops the periodic agent_summary side-query, which has no setting of its
    # own. Upstream and verification steps (re-run after Claude Code updates):
    # https://gist.github.com/flamerix-ai/c3905705cc4205e5de3011fa2e74efce
    home.sessionVariables.BUN_OPTIONS = "--preload=${./no-agent-summary.js}";
    systemd.user.sessionVariables.BUN_OPTIONS = "--preload=${./no-agent-summary.js}";
  };
}
