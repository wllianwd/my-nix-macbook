#!/usr/bin/env bash
set -euo pipefail # Exit on error, undefined variable, or pipe failure

# --- Logging Configuration ---
# Define available log levels (numeric, higher value means more verbose)
LOG_LVL_ERROR=0
LOG_LVL_WARN=1
LOG_LVL_INFO=2
LOG_LVL_DEBUG=3
# Add more levels here if needed, e.g., TRACE=4

# SET DESIRED LOG LEVEL FOR THE SCRIPT EXECUTION HERE:
# For example, to see only warnings and errors: SCRIPT_LOG_LEVEL=$LOG_LVL_WARN
# For informational messages, warnings, and errors: SCRIPT_LOG_LEVEL=$LOG_LVL_INFO
# For full debug output: SCRIPT_LOG_LEVEL=$LOG_LVL_DEBUG
SCRIPT_LOG_LEVEL=$LOG_LVL_INFO # Defaulting to INFO as in your script
# --- End Logging Configuration ---

# --- Helper Functions (modified for log levels) ---
log_info() {
    if [[ $SCRIPT_LOG_LEVEL -ge $LOG_LVL_INFO ]]; then
        echo "[INFO] $1"
    fi
}
log_warn() {
    if [[ $SCRIPT_LOG_LEVEL -ge $LOG_LVL_WARN ]]; then
        echo >&2 "[WARN] $1"
    fi
}
log_error() {
    # Errors are generally always shown unless SCRIPT_LOG_LEVEL is set below LOG_LVL_ERROR
    if [[ $SCRIPT_LOG_LEVEL -ge $LOG_LVL_ERROR ]]; then
        echo >&2 "[ERROR] $1"
    fi
}
log_debug() {
    if [[ $SCRIPT_LOG_LEVEL -ge $LOG_LVL_DEBUG ]]; then
        echo "[DEBUG] $1"
    fi
}
# --- END Helper Functions ---

# --- Prerequisite Command Sanity Checks ---
command -v jq >/dev/null 2>&1 || { log_error "jq is required. Exiting."; exit 1; }
command -v curl >/dev/null 2>&1 || { log_error "curl is required. Exiting."; exit 1; }
command -v nix-hash >/dev/null 2>&1 || { log_error "nix-hash is required. Exiting."; exit 1; }
command -v nix-prefetch-url >/dev/null 2>&1 || { log_error "nix-prefetch-url is required. Exiting."; exit 1; }
command -v awk >/dev/null 2>&1 || { log_error "awk is required. Exiting."; exit 1; }
command -v tail >/dev/null 2>&1 || { log_error "tail is required. Exiting."; exit 1; }

# Check for sort -V capability
sort_v_works=true
SORT_CMD="sort"
if ! printf "1.0\n1.2\n" | sort -V > /dev/null 2>&1; then
    sort_v_works=false
    if command -v gsort >/dev/null 2>&1 && printf "1.0\n1.2\n" | gsort -V > /dev/null 2>&1; then
        SORT_CMD="gsort"; log_debug "Using gsort for version sorting."; sort_v_works=true
    else
        log_debug "Your 'sort' command may not support -V. Version comparison might be less reliable."
    fi
fi

# --- Configuration for Plugin File Path ---
if [[ -z "$MY_NIX_CONFIG_DIR" ]]; then log_error "MY_NIX_CONFIG_DIR not set. Exiting."; exit 1; fi
PLUGINS_JSON_FILE="$MY_NIX_CONFIG_DIR/home/idea/plugins.json"
if [[ ! -f "$PLUGINS_JSON_FILE" ]]; then log_error "Plugins file not found: $PLUGINS_JSON_FILE. Exiting."; exit 1; fi

UPDATES_TO_APPLY=()

# --- Main Logic ---
log_info "Starting IDEA plugin version check for $PLUGINS_JSON_FILE..."

while IFS= read -r plugin_json_line; do
    plugin_id=$(echo "$plugin_json_line" | jq -r '.id')
    current_version=$(echo "$plugin_json_line" | jq -r '.version')
    # Removed current_url reading as it's not used directly for fetching if ID is present

    if [[ "$plugin_id" == "null" || -z "$plugin_id" ]]; then
        log_warn "  Skipping entry: missing or null 'id' in plugins.json. Entry: $plugin_json_line"
        continue
    fi

    # --- Fetch plugin name for logging AND for storing in plugins.json ---
    plugin_display_name_for_log="ID $plugin_id" # Default for logging
    fetched_name_from_api="" # Will store the raw fetched name
    plugin_details_url="https://plugins.jetbrains.com/api/plugins/${plugin_id}"
    api_plugin_details_response=""

    log_debug "  Fetching plugin details from: $plugin_details_url"
    if api_plugin_details_response=$(curl -sS --fail --location "$plugin_details_url" 2>/dev/null); then
        fetched_name_from_api=$(echo "$api_plugin_details_response" | jq -r '.name // empty')
        if [[ -n "$fetched_name_from_api" ]]; then
            plugin_display_name_for_log="'$fetched_name_from_api' (ID: $plugin_id)"
        else
            log_debug "  Could not extract plugin name for ID '$plugin_id' from API details, using ID for logs."
        fi
    else
        log_debug "  Failed to fetch plugin details for ID '$plugin_id', using ID for logs."
    fi
    # --- End fetch plugin name ---

    log_debug "Checking plugin: $plugin_display_name_for_log, current version: $current_version"

    api_url="https://plugins.jetbrains.com/api/plugins/${plugin_id}/updates"; log_debug "  Querying API for updates: $api_url"

    api_response=""; if ! api_response=$(curl -sS --fail --location "$api_url"); then log_debug "  Skipping plugin $plugin_display_name_for_log: Failed API fetch for updates."; continue; fi
    if [[ -z "$api_response" || "$api_response" == "[]" ]]; then log_debug "  No updates in API for plugin $plugin_display_name_for_log."; continue; fi
    latest_update_json=$(echo "$api_response" | jq '.[0]'); if [[ "$latest_update_json" == "null" ]]; then log_debug "  No detailed update info for plugin $plugin_display_name_for_log."; continue; fi

    latest_api_version=$(echo "$latest_update_json" | jq -r '.version'); new_file_path_fragment=$(echo "$latest_update_json" | jq -r '.file')
    if [[ -z "$latest_api_version" || "$latest_api_version" == "null" || -z "$new_file_path_fragment" || "$new_file_path_fragment" == "null" ]]; then
        log_debug "  Skipping plugin $plugin_display_name_for_log: Bad API data for update."; log_debug "  DEBUG JSON: $latest_update_json"; continue; fi
    log_debug "  Latest API version: $latest_api_version"; log_debug "  API File path: $new_file_path_fragment"
    new_plugin_download_url="https://downloads.marketplace.jetbrains.com/files/${new_file_path_fragment}"

    if [[ "$current_version" == "$latest_api_version" ]]; then log_debug "  Plugin $plugin_display_name_for_log is up-to-date."; else
        perform_update=false
        # Version comparison logic
        SORT_CMD_EFFECTIVE="sort"
        if [[ "$sort_v_works" = true ]]; then SORT_CMD_EFFECTIVE="$SORT_CMD"; fi
        older_version=$(printf '%s\n%s\n' "$current_version" "$latest_api_version" | $SORT_CMD_EFFECTIVE -V 2>/dev/null | head -n 1 || true)
        if [[ -n "$older_version" && "$older_version" == "$current_version" && "$current_version" != "$latest_api_version" ]]; then
            perform_update=true
        elif [[ "$sort_v_works" != true && "$latest_api_version" > "$current_version" ]]; then
            perform_update=true
        fi


        if [[ "$perform_update" = true ]]; then
            log_debug "  Update found for plugin $plugin_display_name_for_log: $current_version -> $latest_api_version"; log_debug "  New URL: $new_plugin_download_url"
            new_hash_sri=""; hex_sha256_from_api=$(echo "$latest_update_json" | jq -r '.fileSha256')

            if [[ -n "$hex_sha256_from_api" && "$hex_sha256_from_api" != "null" ]]; then
                log_debug "  SHA256 from API (HEX): $hex_sha256_from_api. Converting..."
                nix_hash_output_b64=""
                if ! nix_hash_output_b64=$(nix-hash --type sha256 --to-base64 "$hex_sha256_from_api" 2>/dev/null); then
                    log_debug "  Skipping plugin $plugin_display_name_for_log: Failed to convert API HEX '$hex_sha256_from_api' to Base64."; continue
                fi
                if [[ -z "$nix_hash_output_b64" ]]; then
                    log_debug "  Skipping plugin $plugin_display_name_for_log: API HEX to Base64 conversion produced empty output for '$hex_sha256_from_api'."; continue
                fi
                new_hash_sri="sha256-${nix_hash_output_b64}"; log_debug "  Converted API hash to SRI: $new_hash_sri"
            else
                log_debug "  SHA256 not in API for plugin $plugin_display_name_for_log v$latest_api_version. Using nix-prefetch-url..."
                raw_prefetched_hash=""
                if ! raw_prefetched_hash=$(nix-prefetch-url --unpack --type sha256 "$new_plugin_download_url" 2>/dev/null | tail -n1); then
                    log_debug "  Skipping plugin $plugin_display_name_for_log: nix-prefetch-url failed."; continue; fi
                if [[ -z "$raw_prefetched_hash" ]]; then log_debug "  Skipping plugin $plugin_display_name_for_log: nix-prefetch-url empty hash."; continue; fi
                log_debug "  Raw hash from nix-prefetch-url (last line): '$raw_prefetched_hash'"

                nix_hash_output_b64=""
                log_debug "  Attempting Lix-specific conversion: nix-hash --base32 --to-base64 --type sha256 <raw_hash>"
                if ! nix_hash_output_b64=$(nix-hash --base32 --to-base64 --type sha256 "$raw_prefetched_hash" 2>/dev/null); then
                     log_debug "  Lix-specific hash conversion command failed or produced no output for raw hash '$raw_prefetched_hash'." # Changed to WARN as it might "succeed" with empty output if Lix allows
                fi

                if [[ -z "$nix_hash_output_b64" ]]; then
                    log_debug "  Skipping plugin $plugin_display_name_for_log: Lix-specific hash conversion produced empty base64 for raw hash '$raw_prefetched_hash'. Ensure Lix command is correct and works."
                    continue
                fi
                new_hash_sri="sha256-${nix_hash_output_b64}"; log_debug "  Converted raw hash to SRI using Lix-specific command: $new_hash_sri"
            fi

            if [[ -z "$new_hash_sri" || "$new_hash_sri" == "sha256-" ]]; then
                log_debug "  Skipping plugin $plugin_display_name_for_log: Final SRI hash is empty or invalid ('$new_hash_sri')."
                continue
            fi

            log_debug "  [SUCCESS] Adding update for plugin $plugin_display_name_for_log: v$latest_api_version, hash $new_hash_sri"

            # Use the fetched_name_from_api for the 'name' field in JSON. Default to empty string if not found.
            name_to_store_in_json="${fetched_name_from_api:-}"

            update_data_json=$(jq -nc \
                --argjson id "$plugin_id" \
                --arg name "$name_to_store_in_json" \
                --arg ver "$latest_api_version" \
                --arg url "$new_plugin_download_url" \
                --arg hash "$new_hash_sri" \
                '{id: $id, name: $name, version: $ver, url: $url, hash: $hash}')
            UPDATES_TO_APPLY+=("$update_data_json")
        else log_debug "  Skipping plugin $plugin_display_name_for_log: API version $latest_api_version not newer or version sort issue."; fi
    fi;
done < <(jq -c '.[]' "$PLUGINS_JSON_FILE")

# --- Apply Updates if Any ---
if [ ${#UPDATES_TO_APPLY[@]} -eq 0 ]; then log_info "All plugins are up-to-date or no applicable updates processed."; exit 0; fi

echo "--------------------------------------------------";
# Ensure summary header prints if updates exist, respecting SCRIPT_LOG_LEVEL for INFO
summary_header_printed=false
if [[ $SCRIPT_LOG_LEVEL -ge $LOG_LVL_INFO ]]; then
    log_info "Plugin updates to be applied automatically:"
    summary_header_printed=true
elif [[ $SCRIPT_LOG_LEVEL -ge $LOG_LVL_WARN ]]; then # If WARN level, still print a basic header
    echo "[INFO] Plugin updates to be applied automatically:" # Forced basic header
    summary_header_printed=true
fi
if [[ "$summary_header_printed" != true && ${#UPDATES_TO_APPLY[@]} -gt 0 ]]; then # Fallback if header didn't print but updates exist
    echo "[INFO] Plugin updates to be applied automatically:"
fi


for item_json_str in "${UPDATES_TO_APPLY[@]}"; do
    u_id=$(echo "$item_json_str" | jq -r '.id')
    # Extract the 'name' field we stored, which came from fetched_name_from_api or was empty
    u_name_for_summary=$(echo "$item_json_str" | jq -r '.name')
    u_ver=$(echo "$item_json_str" | jq -r '.version')

    display_name_for_summary="$u_name_for_summary"
    if [[ -z "$u_name_for_summary" ]]; then # If stored name was empty, use ID for summary
        display_name_for_summary="ID $u_id"
    fi
    echo "  - Plugin: '$display_name_for_summary' (ID: $u_id) ==> New Version: '$u_ver'"
done
echo "--------------------------------------------------"

updates_json_array_string="[$(IFS=,; echo "${UPDATES_TO_APPLY[*]}")]"
jq_update_script='
  ($updates_list | map({(.id | tostring): .}) | add) as $updates_map |
  map(
    .id as $original_id_num |
    ($original_id_num | tostring) as $original_id_str |
    if $updates_map[$original_id_str] then
      .name    = $updates_map[$original_id_str].name | # Add/Update the name field
      .version = $updates_map[$original_id_str].version |
      .url    = $updates_map[$original_id_str].url |
      .hash   = $updates_map[$original_id_str].hash
    else
      .
    end
  )
'
temp_json_output_file="${PLUGINS_JSON_FILE}.tmp"
if jq --argjson updates_list "$updates_json_array_string" "$jq_update_script" "$PLUGINS_JSON_FILE" > "$temp_json_output_file"; then
    mv "$temp_json_output_file" "$PLUGINS_JSON_FILE"; log_info "'$PLUGINS_JSON_FILE' updated."
else log_error "Failed to update '$PLUGINS_JSON_FILE'. Temp file: '$temp_json_output_file'"; exit 1; fi
exit 0
