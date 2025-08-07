#!/bin/bash
# Test suite for gitterbugs enhanced version

set -e

echo "=== Gitterbugs Test Suite ==="
echo

# Test basic functionality
echo "[TEST] Basic tree generation..."
./gitterbugs-enhanced.sh https://github.com/amosWeiskopf/gitterbugs
echo "✓ Basic test passed"
echo

# Test depth limiting
echo "[TEST] Depth limiting (depth=2)..."
./gitterbugs-enhanced.sh -d 2 https://github.com/amosWeiskopf/gitterbugs
echo "✓ Depth limit test passed"
echo

# Test file filtering
echo "[TEST] File type filtering (only .sh files)..."
./gitterbugs-enhanced.sh --only "*.sh" https://github.com/amosWeiskopf/gitterbugs
echo "✓ File filter test passed"
echo

# Test JSON output
echo "[TEST] JSON format output..."
./gitterbugs-enhanced.sh --format json https://github.com/amosWeiskopf/gitterbugs > test_output.json
echo "✓ JSON output test passed"
echo

# Test statistics
echo "[TEST] Repository statistics..."
./gitterbugs-enhanced.sh --stats https://github.com/amosWeiskopf/gitterbugs
echo "✓ Statistics test passed"
echo

# Test color output
echo "[TEST] Colored output..."
./gitterbugs-enhanced.sh --color always https://github.com/amosWeiskopf/gitterbugs
echo "✓ Color output test passed"
echo

# Test help
echo "[TEST] Help system..."
./gitterbugs-enhanced.sh --help > /dev/null
echo "✓ Help test passed"
echo

# Cleanup
rm -f test_output.json gitterbugs_tree.txt

echo "=== All tests passed! ==="