# Changelog

All notable changes to gitterbugs will be documented in this file.

## [2.0.0] - 2024-01-15

### Added
- **Colorized output** with ANSI color codes for different file types
- **File type icons** using Unicode emojis for visual file type recognition
- **Multiple output formats**: tree (default), JSON, Markdown, and CSV
- **Advanced filtering options**:
  - `--only` pattern matching for including specific files
  - `--exclude` pattern matching for excluding files
  - `--min-size` and `--max-size` for size-based filtering
  - `--type` for filtering by predefined file categories
- **Repository statistics** showing file counts, total size, and type distribution
- **Smart caching system** for faster repeated runs
- **Directory size calculation** with `--dir-sizes` option
- **Sorting capabilities** by name, size, type, or modification date
- **Private repository support** via GitHub token authentication
- **Gist support** for analyzing GitHub Gists
- **Progress indicators** with verbose mode
- **Comprehensive help system** with examples and full documentation
- **Configuration support** via config file and environment variables
- **Hidden file support** with `--show-hidden` option

### Changed
- Complete rewrite of the core script for modularity and performance
- Enhanced installer with dependency checking for optional features
- Improved tree rendering algorithm for better Unicode character handling
- File size formatting now supports TB (terabytes) for very large files

### Fixed
- Proper handling of spaces in file names
- Correct tree rendering for deep directory structures
- Better error handling for permission-denied scenarios

## [1.0.0] - 2024-01-01

### Added
- Initial release
- Basic tree generation with file sizes
- GitHub repository cloning
- Simple installation script
- Human-readable file size formatting
- Hidden file exclusion