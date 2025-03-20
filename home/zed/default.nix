{ ... }:

{
  programs.zed-editor = {
    enable = true;
    userSettings = {
      theme = "Catppuccin Macchiato";
      features = {
        copilot = false;
      };
      telemetry = {
        metrics = false;
      };
      inlay_hints = {
        enabled = false;
      };
      buffer_font_family = "MonaspiceNe Nerd Font Propo";
      vim_mode = true;
      ui_font_size = 16;
      buffer_font_size = 16;
      lsp = {
        nixd = {
          settings = {
            diagnostic = {
              suppress = [ "sema-extra-with" ];
            };
          };
          initialization_options = {
            formatting = {
              command = [
                "nixfmt"
                "--quiet"
                "--"
              ];
            };
          };
        };
        nil = {
          settings = {
            diagnostic = {
              ignored = [ "unused_binding" ];
            };
          };
          initialization_options = {
            formatting = {
              command = [
                "nixfmt"
                "--quiet"
                "--"
              ];
            };
          };
        };
      };
    };
    extensions = [
      "nix"
      "tmux"
      "lua"
      "http"
    ];
  };
}
