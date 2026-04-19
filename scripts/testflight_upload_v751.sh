#!/bin/bash
# TestFlight upload — SVLBH Panel v7.5.1 (85)
# Uses ASC API Key 2VRW78KLKM (Co-Work - Admin)
set -euo pipefail

PROJECT_DIR="/Users/patricktest/Developer/svlbhpanel-v5"
PROJECT="$PROJECT_DIR/SVLBH Panel.xcodeproj"
SCHEME="SVLBH Panel"
CONFIG="Release"
ARCHIVE_PATH="$PROJECT_DIR/build/SVLBH-Panel-v751.xcarchive"
EXPORT_DIR="$PROJECT_DIR/build/export-v751"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions.plist"

KEY_ID="2VRW78KLKM"
ISSUER_ID="06df5236-7489-4e45-bca4-1fef3aa9855a"

cd "$PROJECT_DIR"

echo "==> Clean previous build artifacts"
rm -rf "$ARCHIVE_PATH" "$EXPORT_DIR"
mkdir -p "$PROJECT_DIR/build"

echo "==> xcodebuild archive (Release, generic iOS)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID" \
  -authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8" \
  clean archive

echo "==> xcodebuild -exportArchive (app-store-connect destination=upload)"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates \
  -authenticationKeyID "$KEY_ID" \
  -authenticationKeyIssuerID "$ISSUER_ID" \
  -authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"

echo "==> Done. Artifacts:"
ls -lh "$EXPORT_DIR" || true
echo "Build should now be processing on TestFlight."

echo "==> Post-upload automation (What to Test + beta group + review submission)"
# Waits for the build to become VALID on ASC, then:
#  - writes the fr-FR "What to Test" from scripts/whats_to_test_fr.txt
#  - links the build to the external beta group "SVLBH Bash 3 à 5"
#  - submits the build to Apple Beta App Review
# Edit scripts/whats_to_test_fr.txt before running to change the test notes.
# Pass --skip-submit if you only want to link the build without submitting to review.
#
# Uses a dedicated venv at scripts/.venv so pyjwt doesn't clash with Homebrew Python (PEP 668).
# The venv is created automatically on first run.
VENV_DIR="$PROJECT_DIR/scripts/.venv"
VENV_PY="$VENV_DIR/bin/python3"
if [ ! -x "$VENV_PY" ]; then
  echo "  (bootstrapping venv at $VENV_DIR)"
  python3 -m venv "$VENV_DIR"
  "$VENV_PY" -m pip install --quiet --upgrade pip
  "$VENV_PY" -m pip install --quiet 'pyjwt[crypto]'
fi
"$VENV_PY" "$PROJECT_DIR/scripts/testflight_post_upload.py" "$@"
