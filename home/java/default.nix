{ pkgs, ... }:

let jdks = with pkgs; [ openjdk8 openjdk11 openjdk17 openjdk21 openjdk23 ];
in {
  # Install JDKS at ~/.jdks
  home.sessionPath = [ "$HOME/.jdks" ];
  home.file = (builtins.listToAttrs (builtins.map (jdk: {
    name = ".jdks/${jdk.version}";
    value = { source = jdk; };
  }) jdks));

  programs.zsh = {
    # Set java 21 as default
    sessionVariables = { JAVA_HOME = "$HOME/.jdks/${pkgs.openjdk21.version}"; };

    # Define shell aliases for switching Java versions
    shellAliases = builtins.listToAttrs (builtins.map (jdk: {
      name = "jdk" + (builtins.elemAt (builtins.split "\\." jdk.version) 0);
      value =
        "export JAVA_HOME=$HOME/.jdks/${jdk.version} && export PATH=$JAVA_HOME/bin:$PATH; java --version";
    }) jdks);
  };
}
