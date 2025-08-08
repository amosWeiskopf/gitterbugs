#!/bin/bash
# gitterbugs-enhanced: Advanced GitHub repository tree visualizer with 10x features
# Version: 2.0.0

set -e


VERSION="2.0.0"
SCRIPT_NAME=$(basename "$0")

# Default configuration
DEFAULT_DEPTH=999
DEFAULT_FORMAT="tree"
DEFAULT_COLOR="auto"
CACHE_DIR="$HOME/.cache/gitterbugs"
CONFIG_FILE="$HOME/.config/gitterbugs/config"

# Color codes
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
    C_RESET='\033[0m'
    C_BOLD='\033[1m'
    C_DIR='\033[1;34m'      # Blue for directories
    C_EXEC='\033[1;32m'     # Green for executables
    C_LINK='\033[1;36m'     # Cyan for symlinks
    C_ARCHIVE='\033[1;31m'  # Red for archives
    C_IMAGE='\033[1;35m'    # Magenta for images
    C_CODE='\033[1;33m'     # Yellow for code
    C_SIZE='\033[0;90m'     # Gray for sizes
    C_TREE='\033[0;90m'     # Gray for tree lines
else
    C_RESET='' C_BOLD='' C_DIR='' C_EXEC='' C_LINK='' 
    C_ARCHIVE='' C_IMAGE='' C_CODE='' C_SIZE='' C_TREE=''
fi

# File type patterns
declare -A FILE_TYPES=(
    ["code"]="*.py *.js *.ts *.java *.c *.cpp *.h *.go *.rs *.rb *.php *.swift *.kt"
    ["doc"]="*.md *.txt *.pdf *.doc *.docx *.odt"
    ["config"]="*.json *.yaml *.yml *.toml *.ini *.conf *.cfg"
    ["archive"]="*.zip *.tar *.gz *.bz2 *.xz *.7z *.rar"
    ["image"]="*.jpg *.jpeg *.png *.gif *.svg *.bmp *.ico"
    ["video"]="*.mp4 *.avi *.mkv *.mov *.wmv *.flv"
    ["audio"]="*.mp3 *.wav *.ogg *.flac *.aac *.wma"
)

# Icons for file types (Unicode)
declare -A FILE_ICONS=(
    ["dir"]="📁"
    ["code"]="📄"
    ["doc"]="📝"
    ["config"]="⚙️"
    ["archive"]="📦"
    ["image"]="🖼️"
    ["video"]="🎬"
    ["audio"]="🎵"
    ["exec"]="⚡"
    ["link"]="🔗"
    ["default"]="📄"
)

usage() {
    cat << EOF
${C_BOLD}gitterbugs v${VERSION}${C_RESET} - Advanced GitHub repository tree visualizer

${C_BOLD}USAGE:${C_RESET}
    $SCRIPT_NAME [OPTIONS] <GITHUB_URL>

${C_BOLD}OPTIONS:${C_RESET}
    -d, --depth <N>         Maximum depth to traverse (default: unlimited)
    -f, --format <FMT>      Output format: tree, json, markdown, csv (default: tree)
    -o, --output <FILE>     Output to file instead of stdout
    -c, --color <WHEN>      Colorize output: always, never, auto (default: auto)
    --no-size               Don't show file sizes
    --no-icons              Don't show file type icons
    --only <PATTERN>        Only show files matching pattern (can use multiple times)
    --exclude <PATTERN>     Exclude files matching pattern (can use multiple times)
    --min-size <SIZE>       Only show files larger than SIZE (e.g., 1M, 500K)
    --max-size <SIZE>       Only show files smaller than SIZE
    --type <TYPE>           Filter by file type: code, doc, config, archive, image, etc.
    --show-hidden           Include hidden files and directories
    --dir-sizes             Calculate and show directory sizes (slower)
    --sort <FIELD>          Sort by: name, size, type, date (default: name)
    --reverse               Reverse sort order
    --stats                 Show repository statistics at the end
    --cache                 Use cache for faster repeated runs
    --clear-cache           Clear the cache before running
    --auth <TOKEN>          GitHub token for private repos
    --gist                  Treat URL as a GitHub Gist
    -v, --verbose           Show progress and debug information
    -q, --quiet             Suppress all non-essential output
    -h, --help              Show this help message
    -V, --version           Show version information

${C_BOLD}EXAMPLES:${C_RESET}
    # Basic usage
    $SCRIPT_NAME https://github.com/torvalds/linux

    # Limit depth and show only Python files
    $SCRIPT_NAME -d 3 --only "*.py" https://github.com/python/cpython

    # Export as JSON with statistics
    $SCRIPT_NAME --format json --stats -o repo.json https://github.com/user/repo

    # Show large files with directory sizes
    $SCRIPT_NAME --min-size 1M --dir-sizes https://github.com/user/repo

    # Multiple filters and sorting
    $SCRIPT_NAME --type code --exclude "*test*" --sort size --reverse https://github.com/user/repo

${C_BOLD}CONFIGURATION:${C_RESET}
    Config file: $CONFIG_FILE
    Cache directory: $CACHE_DIR

${C_BOLD}ENVIRONMENT VARIABLES:${C_RESET}
    NO_COLOR              Disable colored output
    GITHUB_TOKEN          GitHub authentication token
    GITTERBUGS_CACHE_DIR  Custom cache directory

EOF
}

# Parse command line arguments
parse_args() {
    DEPTH=$DEFAULT_DEPTH
    FORMAT=$DEFAULT_FORMAT
    COLOR=$DEFAULT_COLOR
    OUTPUT_FILE=""
    SHOW_SIZE=true
    SHOW_ICONS=true
    SHOW_HIDDEN=false
    DIR_SIZES=false
    SORT_BY="name"
    REVERSE_SORT=false
    SHOW_STATS=false
    USE_CACHE=false
    CLEAR_CACHE=false
    GITHUB_TOKEN="${GITHUB_TOKEN:-}"
    IS_GIST=false
    VERBOSE=false
    QUIET=false
    
    declare -a ONLY_PATTERNS=()
    declare -a EXCLUDE_PATTERNS=()
    MIN_SIZE=""
    MAX_SIZE=""
    TYPE_FILTER=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--depth)
                DEPTH="$2"
                shift 2
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -c|--color)
                COLOR="$2"
                shift 2
                ;;
            --no-size)
                SHOW_SIZE=false
                shift
                ;;
            --no-icons)
                SHOW_ICONS=false
                shift
                ;;
            --only)
                ONLY_PATTERNS+=("$2")
                shift 2
                ;;
            --exclude)
                EXCLUDE_PATTERNS+=("$2")
                shift 2
                ;;
            --min-size)
                MIN_SIZE="$2"
                shift 2
                ;;
            --max-size)
                MAX_SIZE="$2"
                shift 2
                ;;
            --type)
                TYPE_FILTER="$2"
                shift 2
                ;;
            --show-hidden)
                SHOW_HIDDEN=true
                shift
                ;;
            --dir-sizes)
                DIR_SIZES=true
                shift
                ;;
            --sort)
                SORT_BY="$2"
                shift 2
                ;;
            --reverse)
                REVERSE_SORT=true
                shift
                ;;
            --stats)
                SHOW_STATS=true
                shift
                ;;
            --cache)
                USE_CACHE=true
                shift
                ;;
            --clear-cache)
                CLEAR_CACHE=true
                shift
                ;;
            --auth)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            --gist)
                IS_GIST=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -V|--version)
                echo "gitterbugs v${VERSION}"
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                usage
                exit 1
                ;;
            *)
                REPO_URL="$1"
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "${REPO_URL:-}" ]]; then
        echo "Error: GitHub URL required" >&2
        usage
        exit 1
    fi

    # Handle color option
    case "$COLOR" in
        always) ;;
        never) 
            C_RESET='' C_BOLD='' C_DIR='' C_EXEC='' C_LINK='' 
            C_ARCHIVE='' C_IMAGE='' C_CODE='' C_SIZE='' C_TREE=''
            ;;
        auto)
            if [[ ! -t 1 ]] || [[ "${NO_COLOR:-}" == "1" ]]; then
                C_RESET='' C_BOLD='' C_DIR='' C_EXEC='' C_LINK='' 
                C_ARCHIVE='' C_IMAGE='' C_CODE='' C_SIZE='' C_TREE=''
            fi
            ;;
        *)
            echo "Error: Invalid color option: $COLOR" >&2
            exit 1
            ;;
    esac
}

# Progress indicator
progress() {
    if [[ "$VERBOSE" == "true" ]] && [[ "$QUIET" != "true" ]]; then
        echo -e "${C_BOLD}[*]${C_RESET} $*" >&2
    fi
}

# Convert size string to bytes
size_to_bytes() {
    local size=$1
    local num=${size%[KMGT]B}
    local unit=${size##*[0-9.]}
    
    case $unit in
        K|KB) echo "$((num * 1024))" ;;
        M|MB) echo "$((num * 1024 * 1024))" ;;
        G|GB) echo "$((num * 1024 * 1024 * 1024))" ;;
        T|TB) echo "$((num * 1024 * 1024 * 1024 * 1024))" ;;
        B|"") echo "$num" ;;
        *) echo "0" ;;
    esac
}

# Format bytes to human readable
format_size() {
    local bytes=$1
    if [[ $bytes -gt 1099511627776 ]]; then
        printf "%.1fT" "$(echo "scale=1; $bytes / 1099511627776" | bc)"
    elif [[ $bytes -gt 1073741824 ]]; then
        printf "%.1fG" "$(echo "scale=1; $bytes / 1073741824" | bc)"
    elif [[ $bytes -gt 1048576 ]]; then
        printf "%.1fM" "$(echo "scale=1; $bytes / 1048576" | bc)"
    elif [[ $bytes -gt 1024 ]]; then
        printf "%.1fK" "$(echo "scale=1; $bytes / 1024" | bc)"
    else
        printf "%dB" "$bytes"
    fi
}

# Get file type and icon
get_file_type() {
    local file=$1
    local basename=$(basename "$file")
    
    # Check if it's a directory
    if [[ -d "$file" ]]; then
        echo "dir:${FILE_ICONS[dir]}"
        return
    fi
    
    # Check if it's a symlink
    if [[ -L "$file" ]]; then
        echo "link:${FILE_ICONS[link]}"
        return
    fi
    
    # Check if it's executable
    if [[ -x "$file" ]]; then
        echo "exec:${FILE_ICONS[exec]}"
        return
    fi
    
    # Check against file type patterns
    for type in "${!FILE_TYPES[@]}"; do
        for pattern in ${FILE_TYPES[$type]}; do
            if [[ "$basename" == $pattern ]]; then
                echo "$type:${FILE_ICONS[$type]}"
                return
            fi
        done
    done
    
    echo "default:${FILE_ICONS[default]}"
}

# Calculate directory size
get_dir_size() {
    local dir=$1
    if command -v du >/dev/null 2>&1; then
        du -sb "$dir" 2>/dev/null | awk '{print $1}'
    else
        find "$dir" -type f -exec stat -c %s {} + 2>/dev/null | awk '{sum+=$1} END {print sum+0}'
    fi
}

# Clone or update repository
clone_repo() {
    local url=$1
    local repo_name=$(basename -s .git "$url")
    local target_dir="$repo_name"
    
    if [[ "$USE_CACHE" == "true" ]]; then
        mkdir -p "$CACHE_DIR"
        target_dir="$CACHE_DIR/$repo_name"
    fi
    
    if [[ "$CLEAR_CACHE" == "true" ]] && [[ -d "$target_dir" ]]; then
        progress "Clearing cache for $repo_name"
        rm -rf "$target_dir"
    fi
    
    if [[ ! -d "$target_dir" ]]; then
        progress "Cloning $url..."
        local clone_cmd="git clone --quiet"
        if [[ -n "$GITHUB_TOKEN" ]]; then
            url=$(echo "$url" | sed "s|https://|https://${GITHUB_TOKEN}@|")
        fi
        $clone_cmd "$url" "$target_dir" 2>&1 | while read -r line; do
            [[ "$VERBOSE" == "true" ]] && echo "$line" >&2
        done
    else
        progress "Using existing repository: $repo_name"
        if [[ "$USE_CACHE" == "true" ]]; then
            progress "Updating cached repository..."
            (cd "$target_dir" && git pull --quiet 2>&1) | while read -r line; do
                [[ "$VERBOSE" == "true" ]] && echo "$line" >&2
            done
        fi
    fi
    
    echo "$target_dir"
}

# Build file list with filtering
build_file_list() {
    local dir=$1
    local find_cmd="find '$dir' -mindepth 1"
    
    # Add depth limit
    if [[ "$DEPTH" != "999" ]]; then
        find_cmd="$find_cmd -maxdepth $((DEPTH + 1))"
    fi
    
    # Handle hidden files
    if [[ "$SHOW_HIDDEN" != "true" ]]; then
        find_cmd="$find_cmd -not -path '*/\.*'"
    fi
    
    # Add exclude patterns
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        find_cmd="$find_cmd -not -name '$pattern'"
    done
    
    # Add only patterns
    if [[ ${#ONLY_PATTERNS[@]} -gt 0 ]]; then
        find_cmd="$find_cmd \\("
        local first=true
        for pattern in "${ONLY_PATTERNS[@]}"; do
            if [[ "$first" == "true" ]]; then
                find_cmd="$find_cmd -name '$pattern'"
                first=false
            else
                find_cmd="$find_cmd -o -name '$pattern'"
            fi
        done
        find_cmd="$find_cmd \\)"
    fi
    
    # Add type filter
    if [[ -n "$TYPE_FILTER" ]] && [[ -n "${FILE_TYPES[$TYPE_FILTER]}" ]]; then
        find_cmd="$find_cmd \\("
        local first=true
        for pattern in ${FILE_TYPES[$TYPE_FILTER]}; do
            if [[ "$first" == "true" ]]; then
                find_cmd="$find_cmd -name '$pattern'"
                first=false
            else
                find_cmd="$find_cmd -o -name '$pattern'"
            fi
        done
        find_cmd="$find_cmd \\)"
    fi
    
    # Execute find command
    eval "$find_cmd" 2>/dev/null | while read -r file; do
        # Skip if it's a directory and we're filtering by type
        if [[ -d "$file" ]] && [[ -n "$TYPE_FILTER" ]]; then
            continue
        fi
        
        # Get file size
        local size=0
        if [[ -f "$file" ]]; then
            size=$(stat -c %s "$file" 2>/dev/null || echo 0)
        elif [[ -d "$file" ]] && [[ "$DIR_SIZES" == "true" ]]; then
            progress "Calculating size for $(basename "$file")..."
            size=$(get_dir_size "$file")
        fi
        
        # Apply size filters
        if [[ -n "$MIN_SIZE" ]]; then
            local min_bytes=$(size_to_bytes "$MIN_SIZE")
            [[ $size -lt $min_bytes ]] && continue
        fi
        
        if [[ -n "$MAX_SIZE" ]]; then
            local max_bytes=$(size_to_bytes "$MAX_SIZE")
            [[ $size -gt $max_bytes ]] && continue
        fi
        
        # Get file metadata
        local mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
        local type_info=$(get_file_type "$file")
        local type=${type_info%:*}
        local icon=${type_info#*:}
        
        # Output: path|size|mtime|type|icon
        echo "$file|$size|$mtime|$type|$icon"
    done
}

# Sort file list
sort_file_list() {
    local sort_opts=""
    
    case "$SORT_BY" in
        name) sort_opts="-t| -k1,1" ;;
        size) sort_opts="-t| -k2,2n" ;;
        date) sort_opts="-t| -k3,3n" ;;
        type) sort_opts="-t| -k4,4" ;;
        *) sort_opts="-t| -k1,1" ;;
    esac
    
    if [[ "$REVERSE_SORT" == "true" ]]; then
        sort_opts="$sort_opts -r"
    fi
    
    sort $sort_opts
}

# Generate tree output
generate_tree() {
    local base_dir=$1
    local base_len=${#base_dir}
    
    awk -F'|' -v base_len="$base_len" -v show_size="$SHOW_SIZE" -v show_icons="$SHOW_ICONS" \
        -v c_reset="$C_RESET" -v c_dir="$C_DIR" -v c_exec="$C_EXEC" \
        -v c_link="$C_LINK" -v c_archive="$C_ARCHIVE" -v c_image="$C_IMAGE" \
        -v c_code="$C_CODE" -v c_size="$C_SIZE" -v c_tree="$C_TREE" '
    BEGIN {
        path_count = 0
    }
    {
        paths[path_count] = $1
        sizes[path_count] = $2
        types[path_count] = $4
        icons[path_count] = $5
        path_count++
    }
    END {
        # Build tree structure
        for (i = 0; i < path_count; i++) {
            path = substr(paths[i], base_len + 2)
            # Remove leading slash if present
            if (substr(path, 1, 1) == "/") {
                path = substr(path, 2)
            }
            n_parts = split(path, parts, "/")
            depth = n_parts - 1
            if (depth < 0) depth = 0
            
            # Build indent
            indent = ""
            for (j = 0; j < depth; j++) {
                # Check if parent has more siblings
                has_sibling = 0
                for (k = i + 1; k < path_count; k++) {
                    other_path = substr(paths[k], base_len + 2)
                    if (substr(other_path, 1, 1) == "/") {
                        other_path = substr(other_path, 2)
                    }
                    n_other = split(other_path, other_parts, "/")
                    if (n_other > j && other_parts[j+1] == parts[j+1]) {
                        if (n_other == j + 2) {
                            has_sibling = 1
                            break
                        }
                    }
                }
                if (has_sibling) {
                    indent = indent c_tree "│   " c_reset
                } else {
                    indent = indent "    "
                }
            }
            
            # Check if last in group
            is_last = 1
            for (k = i + 1; k < path_count; k++) {
                other_path = substr(paths[k], base_len + 2)
                if (substr(other_path, 1, 1) == "/") {
                    other_path = substr(other_path, 2)
                }
                n_other_parts = split(other_path, other_parts, "/")
                if (n_other_parts == n_parts && 
                    other_parts[depth] == parts[depth]) {
                    is_last = 0
                    break
                }
            }
            
            # Build branch
            if (is_last) {
                branch = c_tree "└── " c_reset
            } else {
                branch = c_tree "├── " c_reset
            }
            
            # Get color based on type
            color = ""
            if (types[i] == "dir") color = c_dir
            else if (types[i] == "exec") color = c_exec
            else if (types[i] == "link") color = c_link
            else if (types[i] == "archive") color = c_archive
            else if (types[i] == "image") color = c_image
            else if (types[i] == "code") color = c_code
            
            # Build output
            output = indent branch
            if (show_icons == "true" && icons[i] != "") {
                output = output icons[i] " "
            }
            output = output color parts[n_parts] c_reset
            
            if (types[i] == "dir") {
                output = output "/"
            }
            
            if (show_size == "true" && sizes[i] > 0) {
                # Format size
                size_str = ""
                if (sizes[i] > 1099511627776) {
                    size_str = sprintf("%.1fT", sizes[i] / 1099511627776)
                } else if (sizes[i] > 1073741824) {
                    size_str = sprintf("%.1fG", sizes[i] / 1073741824)
                } else if (sizes[i] > 1048576) {
                    size_str = sprintf("%.1fM", sizes[i] / 1048576)
                } else if (sizes[i] > 1024) {
                    size_str = sprintf("%.1fK", sizes[i] / 1024)
                } else {
                    size_str = sizes[i] "B"
                }
                output = output " " c_size "(" size_str ")" c_reset
            }
            
            print output
        }
    }'
}

# Generate JSON output
generate_json() {
    local base_dir=$1
    local base_len=${#base_dir}
    
    echo "{"
    echo '  "repository": "'$(basename "$base_dir")'",'
    echo '  "generated": "'$(date -Iseconds)'",'
    echo '  "files": ['
    
    local first=true
    while IFS='|' read -r path size mtime type icon; do
        local rel_path=${path:$((base_len + 1))}
        local name=$(basename "$path")
        
        [[ "$first" != "true" ]] && echo ","
        first=false
        
        printf '    {\n'
        printf '      "path": "%s",\n' "$rel_path"
        printf '      "name": "%s",\n' "$name"
        printf '      "type": "%s",\n' "$type"
        printf '      "size": %d,\n' "$size"
        printf '      "size_human": "%s",\n' "$(format_size "$size")"
        printf '      "modified": %d\n' "$mtime"
        printf '    }'
    done
    
    echo ""
    echo "  ]"
    echo "}"
}

# Generate Markdown output
generate_markdown() {
    local base_dir=$1
    local repo_name=$(basename "$base_dir")
    
    echo "# Repository Structure: $repo_name"
    echo ""
    echo "Generated on: $(date)"
    echo ""
    echo '```'
    generate_tree "$base_dir"
    echo '```'
    
    if [[ "$SHOW_STATS" == "true" ]]; then
        echo ""
        echo "## Statistics"
        echo ""
        generate_stats_markdown
    fi
}

# Generate CSV output
generate_csv() {
    local base_dir=$1
    local base_len=${#base_dir}
    
    echo "Path,Name,Type,Size,Size_Human,Modified"
    
    while IFS='|' read -r path size mtime type icon; do
        local rel_path=${path:$((base_len + 1))}
        local name=$(basename "$path")
        local size_human=$(format_size "$size")
        local modified=$(date -d "@$mtime" -Iseconds 2>/dev/null || echo "")
        
        printf '"%s","%s","%s",%d,"%s","%s"\n' \
            "$rel_path" "$name" "$type" "$size" "$size_human" "$modified"
    done
}

# Calculate statistics
calculate_stats() {
    awk -F'|' '
    BEGIN {
        total_files = 0
        total_dirs = 0
        total_size = 0
        largest_file = ""
        largest_size = 0
    }
    {
        if ($4 == "dir") {
            total_dirs++
        } else {
            total_files++
            total_size += $2
            if ($2 > largest_size) {
                largest_size = $2
                largest_file = $1
            }
        }
        type_count[$4]++
    }
    END {
        print "total_files=" total_files
        print "total_dirs=" total_dirs
        print "total_size=" total_size
        print "largest_file=" largest_file
        print "largest_size=" largest_size
        for (type in type_count) {
            print "type_" type "=" type_count[type]
        }
    }'
}

# Generate statistics output
generate_stats() {
    local stats=$(calculate_stats)
    eval "$stats"
    
    echo ""
    echo "${C_BOLD}Repository Statistics:${C_RESET}"
    echo "  Total files: $total_files"
    echo "  Total directories: $total_dirs"
    echo "  Total size: $(format_size "$total_size")"
    if [[ -n "$largest_file" ]]; then
        echo "  Largest file: $(basename "$largest_file") ($(format_size "$largest_size"))"
    fi
    echo ""
    echo "${C_BOLD}File types:${C_RESET}"
    for var in $(set | grep "^type_" | grep -v "^type_count"); do
        type=${var#type_}
        type=${type%=*}
        count=${var#*=}
        [[ "$type" != "dir" ]] && echo "  $type: $count"
    done
}

# Generate statistics for markdown
generate_stats_markdown() {
    local stats=$(calculate_stats)
    eval "$stats"
    
    echo "- **Total files**: $total_files"
    echo "- **Total directories**: $total_dirs"
    echo "- **Total size**: $(format_size "$total_size")"
    if [[ -n "$largest_file" ]]; then
        echo "- **Largest file**: \`$(basename "$largest_file")\` ($(format_size "$largest_size"))"
    fi
    echo ""
    echo "### File Types"
    echo ""
    for var in $(set | grep "^type_" | grep -v "^type_count"); do
        type=${var#type_}
        type=${type%=*}
        count=${var#*=}
        [[ "$type" != "dir" ]] && echo "- $type: $count"
    done
}

# Main function
main() {
    parse_args "$@"
    
    # Setup cache directory
    mkdir -p "$CACHE_DIR"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Clone or update repository
    progress "Processing repository..."
    local repo_dir=$(clone_repo "$REPO_URL")
    
    # Build and sort file list
    progress "Building file tree..."
    local file_list=$(build_file_list "$repo_dir" | sort_file_list)
    
    # Generate output based on format
    local output=""
    case "$FORMAT" in
        tree)
            output=$(echo "$file_list" | generate_tree "$repo_dir")
            ;;
        json)
            output=$(echo "$file_list" | generate_json "$repo_dir")
            ;;
        markdown)
            output=$(echo "$file_list" | generate_markdown "$repo_dir")
            ;;
        csv)
            output=$(echo "$file_list" | generate_csv "$repo_dir")
            ;;
        *)
            echo "Error: Unknown format: $FORMAT" >&2
            exit 1
            ;;
    esac
    
    # Output results
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$output" > "$OUTPUT_FILE"
        [[ "$QUIET" != "true" ]] && echo "Output saved to: $OUTPUT_FILE"
    else
        echo "$output"
    fi
    
    # Show statistics if requested
    if [[ "$SHOW_STATS" == "true" ]] && [[ "$FORMAT" == "tree" ]]; then
        echo "$file_list" | generate_stats
    fi
}

# Run main function
main "$@"