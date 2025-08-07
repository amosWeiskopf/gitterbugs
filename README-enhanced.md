# gitterbugs v2.0 - Enhanced Edition
A blazing fast, feature-rich tree builder for any public GitHub repo via the Linux shell

> `gitterbugs` (gbgs) clones, analyzes and renders a beautiful, readable and size-annotated tree of any GitHub repository in seconds - now with 10x more features!

## 🚀 What's New in v2.0

- **🎨 Colorized Output**: File types are color-coded with icons for instant recognition
- **📊 Multiple Formats**: Export as tree, JSON, Markdown, or CSV
- **🔍 Advanced Filtering**: Filter by file type, size, pattern, or custom expressions
- **📈 Repository Statistics**: Get insights about file counts, sizes, and types
- **⚡ Smart Caching**: Lightning-fast repeated runs with intelligent cache management
- **📁 Directory Sizes**: Calculate and display cumulative directory sizes
- **🔐 Private Repos**: Support for authenticated access to private repositories
- **🎯 Precise Control**: Depth limiting, sorting options, and fine-grained output control

## 📸 Quick Demo

```bash
$ gbgs https://github.com/torvalds/linux

📁 linux/
├── 📝 README (4.3K)
├── ⚙️ Makefile (7.1K)
├── 📁 arch/
│   └── 📁 x86/
│       └── 📄 entry.S (1.5K)
└── 📁 init/
    └── 📄 main.c (5.9K)

Repository Statistics:
  Total files: 75,432
  Total directories: 4,521
  Total size: 1.2G
  Largest file: vmlinux.lds (521.3M)
```

## 🏃 Quick Install

```bash
# Install the enhanced version
git clone https://github.com/amosWeiskopf/gitterbugs
cd gitterbugs
./install.sh
```

Or one-liner:
```bash
curl -fsSL https://raw.githubusercontent.com/amosWeiskopf/gitterbugs/main/install.sh | sh
```

## 🎯 Usage Examples

### Basic Usage
```bash
# Simple tree view
gbgs https://github.com/YourOrg/YourRepo

# With colorized output and icons
gbgs --color always https://github.com/facebook/react
```

### Advanced Filtering
```bash
# Only show Python files, max depth 3
gbgs -d 3 --only "*.py" https://github.com/python/cpython

# Exclude test files and node_modules
gbgs --exclude "*test*" --exclude "node_modules" https://github.com/nodejs/node

# Show only large files (> 1MB)
gbgs --min-size 1M https://github.com/torvalds/linux

# Filter by file type
gbgs --type code https://github.com/microsoft/vscode
```

### Output Formats
```bash
# Export as JSON
gbgs --format json -o repo-structure.json https://github.com/user/repo

# Generate Markdown documentation
gbgs --format markdown --stats > PROJECT_STRUCTURE.md https://github.com/user/repo

# Create CSV for spreadsheet analysis
gbgs --format csv --dir-sizes -o analysis.csv https://github.com/user/repo
```

### Sorting and Organization
```bash
# Sort by file size (largest first)
gbgs --sort size --reverse https://github.com/user/repo

# Sort by modification date
gbgs --sort date https://github.com/user/repo

# Show directory sizes and sort by size
gbgs --dir-sizes --sort size https://github.com/user/repo
```

### Performance and Caching
```bash
# Use cache for faster repeated runs
gbgs --cache https://github.com/large/repository

# Clear cache and re-fetch
gbgs --clear-cache https://github.com/user/repo

# Verbose mode to see progress
gbgs -v https://github.com/very/large/repo
```

### Private Repositories
```bash
# Using environment variable
export GITHUB_TOKEN=your_github_token
gbgs https://github.com/YourOrg/private-repo

# Using command line
gbgs --auth your_github_token https://github.com/YourOrg/private-repo
```

## 📋 Full Options Reference

| Option | Description |
|--------|-------------|
| `-d, --depth <N>` | Maximum depth to traverse |
| `-f, --format <FMT>` | Output format: tree, json, markdown, csv |
| `-o, --output <FILE>` | Save output to file |
| `-c, --color <WHEN>` | Colorize output: always, never, auto |
| `--no-size` | Don't show file sizes |
| `--no-icons` | Don't show file type icons |
| `--only <PATTERN>` | Only show files matching pattern |
| `--exclude <PATTERN>` | Exclude files matching pattern |
| `--min-size <SIZE>` | Minimum file size filter |
| `--max-size <SIZE>` | Maximum file size filter |
| `--type <TYPE>` | Filter by file type |
| `--show-hidden` | Include hidden files |
| `--dir-sizes` | Calculate directory sizes |
| `--sort <FIELD>` | Sort by: name, size, type, date |
| `--reverse` | Reverse sort order |
| `--stats` | Show repository statistics |
| `--cache` | Use cache for faster runs |
| `--clear-cache` | Clear cache before running |
| `--auth <TOKEN>` | GitHub authentication token |
| `-v, --verbose` | Show progress information |
| `-q, --quiet` | Suppress non-essential output |

## 🎨 File Type Categories

| Type | Extensions | Icon | Color |
|------|------------|------|-------|
| code | .py .js .ts .java .c .cpp .go .rs | 📄 | Yellow |
| doc | .md .txt .pdf .doc | 📝 | Default |
| config | .json .yaml .yml .toml .ini | ⚙️ | Default |
| archive | .zip .tar .gz .bz2 | 📦 | Red |
| image | .jpg .png .gif .svg | 🖼️ | Magenta |
| directory | - | 📁 | Blue |
| executable | - | ⚡ | Green |
| symlink | - | 🔗 | Cyan |

## 📊 Output Format Examples

### JSON Format
```json
{
  "repository": "gitterbugs",
  "generated": "2024-01-15T10:30:00Z",
  "files": [
    {
      "path": "README.md",
      "name": "README.md",
      "type": "doc",
      "size": 4521,
      "size_human": "4.4K",
      "modified": 1705315800
    }
  ]
}
```

### Markdown Format
```markdown
# Repository Structure: gitterbugs

Generated on: Mon Jan 15 10:30:00 2024

\```
gitterbugs/
├── 📝 README.md (4.4K)
├── ⚡ install.sh (2.1K)
└── 📄 gitterbugs-enhanced.sh (18.7K)
\```

## Statistics

- **Total files**: 3
- **Total directories**: 0
- **Total size**: 25.2K
```

## 🛠️ Configuration

Gitterbugs stores its configuration and cache in:
- Config: `~/.config/gitterbugs/`
- Cache: `~/.cache/gitterbugs/`

Environment variables:
- `NO_COLOR`: Disable colored output
- `GITHUB_TOKEN`: GitHub authentication token
- `GITTERBUGS_CACHE_DIR`: Custom cache directory

## 🚀 Performance

- **Fast**: ~100ms on typical repos
- **Efficient**: Streams output, low memory usage
- **Cached**: Intelligent caching for repeated runs
- **Parallel**: Utilizes multiple cores when available

## 🤝 Comparison

| Feature | `tree` | `ls -R` | `gitterbugs v1` | `gitterbugs v2` |
|---------|--------|---------|-----------------|-----------------|
| Recursive | ✓ | ✓ | ✓ | ✓ |
| Skip hidden files | ✗ | ✗ | ✓ | ✓ |
| Pretty tree layout | ✓ | ✗ | ✓ | ✓ |
| File sizes | ✗ | ✗ | ✓ | ✓ |
| Colors & icons | ✗ | ✗ | ✗ | ✓ |
| Multiple formats | ✗ | ✗ | ✗ | ✓ |
| Advanced filtering | Limited | ✗ | ✗ | ✓ |
| GitHub support | ✗ | ✗ | ✓ | ✓ |
| Statistics | ✗ | ✗ | ✗ | ✓ |
| Caching | ✗ | ✗ | ✗ | ✓ |

## 📝 License

MIT. Use it, remix it, monetize it - it's yours to enjoy!

## 👨‍💻 Author

Enhanced with passion by the open source community  
Original creation by [@AmosWeiskopf](https://github.com/amosWeiskopf)

## 🔮 Future Ideas

- [ ] Interactive TUI mode with navigation
- [ ] Git history integration
- [ ] Language-specific analysis
- [ ] Export to graph visualization
- [ ] Plugin system for custom filters
- [ ] Web UI companion

## 🤔 Why We Made This

The original gitterbugs was great for procrastination. This enhanced version is perfect for *advanced* procrastination - with statistics, colors, and multiple export formats to really avoid getting work done in style!