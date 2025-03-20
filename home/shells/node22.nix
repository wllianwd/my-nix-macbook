{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell { buildInputs = [ pkgs.git pkgs.nodejs_22 pkgs.yarn ]; }
