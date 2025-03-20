#!/bin/bash

# Check if the -i argument is provided
if [[ -z "$1" || "$1" != "-i" ]]; then
  echo "Usage: $0 -i <input_file_path>"
  exit 1
fi

# Extract the input file path
input_file="$2"

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
  echo "Error: Input file '$input_file' not found."
  exit 1
fi

# Get the public SSH key content
public_key=$(cat "$MY_NIX_CONFIG_DIR/uncommited/id_nix.pub")

# Extract the filename from the input path
input_filename=$(basename "$input_file")

# Create the secrets.nix file
pushd "$MY_NIX_CONFIG_DIR/home/ragenix/secrets" > /dev/null

secrets_nix_content="let
  key1 = \"$public_key\";
  users = [ key1 ];
in
{
  \"$input_filename.age\".publicKeys = users;
}"

fake_editor="#!/bin/bash
cat >\"\$1\"
exit 0"

echo "$fake_editor" > fake-editor.sh
chmod +x fake-editor.sh
echo "$secrets_nix_content" > secrets.nix

# Enter nix shell and execute ragenix, then exit
cat $input_file | ragenix --editor $MY_NIX_CONFIG_DIR/home/ragenix/secrets/fake-editor.sh --edit $input_filename.age -i $MY_NIX_CONFIG_DIR/uncommited/id_nix

rm $MY_NIX_CONFIG_DIR/home/ragenix/secrets/fake-editor.sh
rm $MY_NIX_CONFIG_DIR/home/ragenix/secrets/secrets.nix

exit

# Clean up and exit
popd > /dev/null
