{ ... }:

{
  homebrew = {
    enable = false;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    casks = [ ];
  };

}
