#!/bin/bash
set -e

APP_NAME="CreatorHub"
APP_BUNDLE="Creator Hub.app"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"
RESOURCES_DIR="${APP_BUNDLE}/Contents/Resources"

echo "Cleaning old build..."
rm -rf "${APP_BUNDLE}"
rm -rf *.app
rm -rf *.zip

echo "Creating App Bundle structure..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "Copying Info.plist and Resources..."
cp Info.plist "${APP_BUNDLE}/Contents/"

mkdir -p Resources

# Download FFmpeg if missing
if [ ! -f "Resources/ffmpeg" ]; then
    echo "Downloading FFmpeg..."
    curl -L "https://evermeet.cx/ffmpeg/getrelease/zip" -o "Resources/ffmpeg.zip"
    unzip -q "Resources/ffmpeg.zip" -d "Resources/"
    rm "Resources/ffmpeg.zip"
    chmod +x Resources/ffmpeg
fi

# Download Pandoc if missing
if [ ! -f "Resources/pandoc" ]; then
    echo "Downloading Pandoc..."
    PANDOC_URL=$(curl -s https://api.github.com/repos/jgm/pandoc/releases/latest | grep browser_download_url | grep arm64-macOS.zip | cut -d '"' -f 4)
    if [ ! -z "$PANDOC_URL" ]; then
        curl -L "$PANDOC_URL" -o "Resources/pandoc.zip"
        unzip -q "Resources/pandoc.zip" -d "Resources/"
        find Resources -name "pandoc" -type f -perm +111 -exec mv {} Resources/ \;
        rm -rf Resources/pandoc.zip Resources/pandoc-*
        chmod +x Resources/pandoc
    fi
fi



if [ -d "Resources" ]; then
    cp -R Resources/* "${RESOURCES_DIR}/" || true
fi

echo "Compiling Swift files..."
swiftc -O -whole-module-optimization -gnone -parse-as-library \
  -sdk "$(xcrun --show-sdk-path --sdk macosx)" \
  -target "$(uname -m)-apple-macosx12.0" \
  -framework AppKit -framework SwiftUI -framework Vision -framework IOKit -framework ScreenCaptureKit -framework Speech -framework AVFoundation \
  -o "${MACOS_DIR}/${APP_NAME}" \
  Sources/*.swift

echo "Applying Anti-Decompilation Stripping..."
strip -S "${MACOS_DIR}/${APP_NAME}"

echo "Signing App Bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Creating Distribution Package..."
zip -q -r -y "CreatorHub_Ultimate.zip" "${APP_BUNDLE}"

echo "Build successful! App created at ${APP_BUNDLE}"
echo "Distribution package ready: CreatorHub_Ultimate.zip"
