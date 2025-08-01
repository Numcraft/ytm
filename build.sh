#!/usr/bin/env bash

set -euo pipefail

APP_ID="com.google.android.apps.youtube.music"
ARCH="arm64-v8a"
SIGNATURE="a2a1ad7ba7f41dfca4514e2afeb90691719af6d0fdbed4b09bbf0ed897701ceb"

CLI_VERSION=$(curl -s https://api.github.com/repos/ReVanced/revanced-cli/releases/latest | jq -r '.tag_name' | sed 's/^v//')
PATCHES_VERSION=$(curl -s https://api.github.com/repos/inotia00/revanced-patches/releases/latest | jq -r '.tag_name' | sed 's/^v//')

echo "Downloading revanced-cli version $CLI_VERSION..."
curl -sLo cli.jar "https://github.com/ReVanced/revanced-cli/releases/download/v$CLI_VERSION/revanced-cli-$CLI_VERSION-all.jar"

echo "Downloading revanced-patches version $PATCHES_VERSION..."
curl -sLo patches.rvp "https://github.com/inotia00/revanced-patches/releases/download/v$PATCHES_VERSION/patches-$PATCHES_VERSION.rvp"

APP_VERSION=$(java -jar cli.jar list-versions --filter-package-names $APP_ID patches.rvp | awk '/^\t/ {print $1}' | sort -Vr | head -n 1)
APK_PATH="$APP_ID-$APP_VERSION.apk"
PATCHED_APK_PATH="$APP_ID-$APP_VERSION-patched.apk"

echo "Downloading $APP_ID version $APP_VERSION..."
./apkdl.py "$APP_ID" "$APP_VERSION" "$ARCH" "$APK_PATH"

echo "Verifying APK signature..."
if apksigner verify --print-certs "$APK_PATH" | grep -Fx "Signer #1 certificate SHA-256 digest: $SIGNATURE"; then
  echo "OK"
else
  echo "Failed to verify APK signature, expected $SIGNATURE"
  echo "Exiting..."
  exit 1
fi

echo "Patching and signing APK..."
echo "$KEYSTORE" | base64 -d > revanced.keystore
java -jar cli.jar patch \
  --patches patches.rvp \
  --keystore revanced.keystore \
  --keystore-password $KEYSTORE_PASSWORD \
  --keystore-entry-password $KEYSTORE_PASSWORD \
  --out "$PATCHED_APK_PATH" \
  "$APK_PATH"


release_notes=$(cat <<-EOF
CLI version: $CLI_VERSION
Patches version: $PATCHES_VERSION
APP version: $APP_VERSION
EOF
)

last_release_notes=$(gh release view --json body | jq -r '.body' || true)

if [[ "$release_notes" == "$last_release_notes" ]]; then
  echo "Release for this version already exist. Exiting..."
  exit 0
fi

echo "Creating new release..."
tag=$(date +%Y%m%d)
gh release create "$tag" --title "$tag" --notes "$release_notes" "$PATCHED_APK_PATH"
