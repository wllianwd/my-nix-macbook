{ ... }:

let
  global = import ../../global.nix;
in
{
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        theme = {
          enable = true;
          name = "gruvbox";
          style = "dark";
        };
        statusline.lualine.enable = true;
        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;

        lsp = {
          enable = true;
        };

        languages = {
          enableTreesitter = true;

          ts.enable = true;
          rust.enable = true;

          nix = {
            enable = true;
            lsp = {
              options = {
                nix_darwin = {
                  expr = "(builtins.getFlake \"${global.nixConfigDirectory}\").darwinConfigurations.\"${global.host}\".options";
                };
                home_manager = {
                  expr = "(builtins.getFlake \"${global.nixConfigDirectory}\").homeConfigurations.\"${global.username}\".options";
                };
              };
            };
          };
        };
      };
    };
  };
}
