#!/bin/bash

set -e

INSTALL_PATH="$HOME/.local/bin"
ALIAS_CMD="gbgs"

echo "[+] Checking dependencies..."

install_if_missing() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[-] Missing '$1' – installing..."
    sudo apt-get update -qq
    sudo apt-get install -y "$2"
  else
    echo "[✓] $1 is installed."
  fi
}

install_if_missing git git
install_if_missing curl curl
install_if_missing awk gawk
install_if_missing findutils findutils
install_if_missing stat coreutils

mkdir -p "$INSTALL_PATH"

echo "[+] Installing gitterbugs to $INSTALL_PATH..."

cat > "$INSTALL_PATH/$ALIAS_CMD" << 'EOF'
#!/bin/bash
# gitterbugs: Clone a GitHub repo and output a pretty tree view with file sizes

REPO_URL="$1"
[ -z "$REPO_URL" ] && { echo "Usage: gitterbugs <GitHub repo URL>"; exit 1; }

REPO_NAME=$(basename -s .git "$REPO_URL")
TARGET_DIR="$REPO_NAME"
OUTPUT_FILE="${REPO_NAME}_tree.txt"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Cloning $REPO_URL..."
  git clone --quiet "$REPO_URL"
else
  echo "Using existing local repo: $REPO_NAME"
fi

cd "$TARGET_DIR"

find . -not -path '*/\.*' -print | sort > ../all_paths.txt

awk '
  BEGIN {
    FS="/"
    path_count = 0
  }
  {
    paths[path_count++] = $0
  }
  END {
    for (i = 0; i < path_count; i++) {
      path = paths[i]
      depth = split(path, parts, "/") - 1
      indent = ""
      for (j = 1; j < depth; j++) indent = indent "│   "

      curr_depth = depth
      next_depth = (i+1 < path_count) ? split(paths[i+1], tmp, "/") - 1 : 0
      is_last = (next_depth <= curr_depth)
      branch = is_last ? "└── " : "├── "

      if (system("[ -d \"" path "\" ]") == 0) {
        print indent branch parts[depth + 1] "/"
      } else {
        cmd = "stat -c \"%s\" \"" path "\""
        cmd | getline size
        close(cmd)

        hum = size
        if (size > 1048576) hum = sprintf("%.1fM", size / 1048576)
        else if (size > 1024) hum = sprintf("%.1fK", size / 1024)
        else hum = size "B"

        print indent branch parts[depth + 1] " (" hum ")"
      }
    }
  }
' ../all_paths.txt > "../$OUTPUT_FILE"

cd ..
rm all_paths.txt
echo "Tree saved to $OUTPUT_FILE"
EOF

chmod +x "$INSTALL_PATH/$ALIAS_CMD"

if [[ ":$PATH:" != *":$INSTALL_PATH:"* ]]; then
  echo
  echo "[!] Add this to your shell config (e.g. ~/.bashrc or ~/.zshrc):"
  echo "export PATH=\"\$PATH:$INSTALL_PATH\""
  echo
else
  echo "[✓] Installed. Try:"
  echo "gitterbugs https://github.com/torvalds/linux"
fi
