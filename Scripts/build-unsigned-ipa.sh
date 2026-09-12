#!/usr/bin/env bash
set -euo pipefail

upstream_commit="ad39249acd2da4ebf485ff7a58f3865412cdb634"
workspace_root="${GITHUB_WORKSPACE:-$(pwd)}"
source_root="$workspace_root/build-source"
derived_data="$workspace_root/build/DerivedData"
output_root="$workspace_root/build/output"
configuration="Release"

rm -rf "$source_root" "$derived_data" "$output_root"
mkdir -p "$output_root/Payload"

git clone --no-checkout https://github.com/isaakhanimann/psychonautwiki-journal-ios.git "$source_root"
git -C "$source_root" checkout --detach "$upstream_commit"

python3 - "$source_root" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
project = root / "PsychonautWiki Journal.xcodeproj" / "project.pbxproj"
text = project.read_text(encoding="utf-8")

replacements = {
    'isaak.PsychonautWiki-Journal-Debug.TimelineWidget': 'com.artkos078.psychonautjournal.debug.widget',
    'isaak.PsychonautWiki-Journal.TimelineWidget': 'com.artkos078.psychonautjournal.widget',
    'isaak.PsychonautWiki-Journal-Debug': 'com.artkos078.psychonautjournal.debug',
    'isaak.PsychonautWiki-Journal': 'com.artkos078.psychonautjournal',
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"Expected bundle identifier not found: {old}")
    text = text.replace(old, new)

text = "\n".join(
    line for line in text.splitlines()
    if "DEVELOPMENT_TEAM = 6S7AHDRUD6;" not in line
) + "\n"
project.write_text(text, encoding="utf-8")

entitlements = root / "PsychonautWiki Journal" / "PsychonautWiki Journal.entitlements"
entitlements.write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" '
    '"http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
    '<plist version="1.0">\n<dict/>\n</plist>\n',
    encoding="utf-8",
)
PY

xcodebuild \
  -project "$source_root/PsychonautWiki Journal.xcodeproj" \
  -scheme "PsychonautWiki Journal" \
  -configuration "$configuration" \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$derived_data" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  build

app_path="$derived_data/Build/Products/${configuration}-iphoneos/Journal.app"
if [[ ! -d "$app_path" ]]; then
  app_path="$(find "$derived_data/Build/Products/${configuration}-iphoneos" -maxdepth 1 -type d -name '*.app' -print -quit)"
fi
if [[ -z "$app_path" || ! -d "$app_path" ]]; then
  echo "Build completed but no app bundle was found." >&2
  exit 1
fi

cp -R "$app_path" "$output_root/Payload/"
ipa_path="$output_root/PsychonautWiki-Journal-unsigned.ipa"
(
  cd "$output_root"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent Payload "$(basename "$ipa_path")"
)
/usr/bin/shasum -a 256 "$ipa_path" > "$ipa_path.sha256"
echo "Unsigned IPA: $ipa_path"
