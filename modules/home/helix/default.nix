{
  config,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:

{
  home.sessionVariables = {
    EDITOR = "hx";
  };

  # LSP packages used in languages.toml
  home.packages = (with pkgs; [
    alejandra
    asm-lsp
    bash-language-server
    beancount-language-server
    buf
    clang-tools
    clojure-lsp
    cmake-language-server
    cuelsp
    delve
    docker-compose-language-service
    dockerfile-language-server
    dprint
    elixir-ls
    elmPackages.elm-language-server
    fish-lsp
    fortls
    golangci-lint
    gopls
    graphql-language-service-cli
    harper
    haskell-language-server
    helm-ls
    hyprls
    jdt-language-server
    jq-lsp
    jsonnet-language-server
    julia
    just-lsp
    kotlin-language-server
    llvmPackages_latest.lldb
    lua-language-server
    marksman
    metals
    nil
    nixfmt-rfc-style
    ocamlPackages.ocaml-lsp
    omnisharp-roslyn
    openscad-lsp
    phpactor
    prisma-engines
    pyright
    ruff
    rust-analyzer
    rustfmt
    solargraph
    stylua
    superhtml
    taplo
    terraform-ls
    texlab
    tinymist
    ty
    typescript-language-server
    typstyle
    vscode-langservers-extracted
    yaml-language-server
    yamlfmt
    zig
    zls
  ]) ++ (with pkgs-unstable; [
    prettier # Leaving it in unstable until CVEs are patched
  ]);

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        bufferline = "multiple";
        cursorline = false;
        rulers = [ ];
        true-color = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        indent-guides = {
          character = "╎";
          render = false;
        };
        lsp.display-messages = true;
        statusline = {
          left = [
            "mode"
            "spinner"
            "version-control"
            "file-name"
          ];
          center = [ "file-type" ];
        };
      };

      keys.insert = {
        j = {
          k = "normal_mode";
          j = "normal_mode";
        }; # Maps `jk` and `jj` to exit insert mode
      };

    };
    languages = builtins.fromTOML (builtins.readFile ./languages.toml);
  };
}
