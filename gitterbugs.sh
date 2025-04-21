#!/bin/bash

# gitterbugs.sh: install the `gitterbugs` command for pretty tree printing of GitHub repos

set -e

INSTALL_PATH="$HOME/.local/bin"
ALIAS_CMD="gitterbugs"

mkdir -p "$INSTALL_PATH"

echo "🐞 Installing gitterbugs to $INSTALL_PATH..."

# Write the main tool
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
echo "✅ Pretty tree with sizes saved to $OUTPUT_FILE"
EOF

chmod +x "$INSTALL_PATH/$ALIAS_CMD"

# Suggest adding to PATH
if [[ ":$PATH:" != *":$INSTALL_PATH:"* ]]; then
  echo "🔧 Add this to your shell config (e.g. ~/.bashrc or ~/.zshrc):"
  echo "export PATH=\"\$PATH:$INSTALL_PATH\""
else
  echo "✅ Installed. Try:"
  echo "$ALIAS_CMD https://github.com/amosWeiskopf/gitterbugs"
fi
