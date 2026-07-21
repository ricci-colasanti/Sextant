#!/bin/bash
# build.sh - Build Sextant for all platforms

set -e  # Exit on error

echo "════════════════════════════════════════════════════════"
echo "  Building Sextant for All Platforms"
echo "════════════════════════════════════════════════════════"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -f sextant-linux sextant-linux-arm64 sextant-windows.exe sextant-macos sextant-macos-arm64
echo "✅ Clean complete"
echo ""

# Build for Linux (x86_64)
echo "🐧 Building for Linux (x86_64)..."
GOOS=linux GOARCH=amd64 go build -o sextant-linux main.go
chmod +x sextant-linux
echo "✅ sextant-linux"
file sextant-linux | head -1
ls -lh sextant-linux | awk '{print "   Size: " $5}'
echo ""

# Build for Linux (ARM64)
echo "🐧 Building for Linux (ARM64)..."
GOOS=linux GOARCH=arm64 go build -o sextant-linux-arm64 main.go
chmod +x sextant-linux-arm64
echo "✅ sextant-linux-arm64"
file sextant-linux-arm64 | head -1
ls -lh sextant-linux-arm64 | awk '{print "   Size: " $5}'
echo ""

# Build for Windows (x86_64)
echo "🪟 Building for Windows (x86_64)..."
GOOS=windows GOARCH=amd64 go build -o sextant-windows.exe main.go
echo "✅ sextant-windows.exe"
ls -lh sextant-windows.exe | awk '{print "   Size: " $5}'
echo ""

# Build for macOS (Intel x86_64)
echo "🍎 Building for macOS (Intel x86_64)..."
GOOS=darwin GOARCH=amd64 go build -o sextant-macos main.go
chmod +x sextant-macos
echo "✅ sextant-macos"
file sextant-macos | head -1
ls -lh sextant-macos | awk '{print "   Size: " $5}'
echo ""

# Build for macOS (Apple Silicon ARM64)
echo "🍎 Building for macOS (Apple Silicon ARM64)..."
GOOS=darwin GOARCH=arm64 go build -o sextant-macos-arm64 main.go
chmod +x sextant-macos-arm64
echo "✅ sextant-macos-arm64"
file sextant-macos-arm64 | head -1
ls -lh sextant-macos-arm64 | awk '{print "   Size: " $5}'
echo ""

# Summary
echo "════════════════════════════════════════════════════════"
echo "  ✅ Build Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📦 Binaries created:"
echo "   Linux (x86_64):     sextant-linux"
echo "   Linux (ARM64):      sextant-linux-arm64"
echo "   Windows (x86_64):   sextant-windows.exe"
echo "   macOS (Intel):      sextant-macos"
echo "   macOS (Apple Silicon): sextant-macos-arm64"
echo ""
echo "▶️  To run:"
echo "   Linux (x86_64):   ./sextant-linux config.yaml"
echo "   Linux (ARM64):    ./sextant-linux-arm64 config.yaml"
echo "   Windows:          sextant-windows.exe config.yaml"
echo "   macOS (Intel):    ./sextant-macos config.yaml"
echo "   macOS (Apple Silicon): ./sextant-macos-arm64 config.yaml"
echo ""
echo "🔍 Verify no external dependencies:"
echo "   Linux:   ldd sextant-linux"
echo "   Windows: (check with depends.exe or similar)"
echo "   macOS:   otool -L sextant-macos"
echo "   macOS:   otool -L sextant-macos-arm64"
echo ""
echo "📝 To check architecture:"
echo "   Linux:   file sextant-*"
echo "   macOS:   file sextant-macos*"