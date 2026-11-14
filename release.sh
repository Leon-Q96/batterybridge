#!/bin/zsh
# Builds a release without leaving searchable staging .app bundles behind.
set -eu
project_dir="${0:A:h}"
output_dir="${1:-${project_dir}/../../outputs}"
mkdir -p "${output_dir}" "${project_dir}/release.noindex"
output_dir="${output_dir:A}"
"${project_dir}/build.sh" "${project_dir}/build.noindex"
bundle_dir="${project_dir}/build.noindex/BatteryBridge.app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${bundle_dir}/Contents/Info.plist")
release_dir=$(mktemp -d "${project_dir}/release.noindex/stage.XXXXXX")
trap 'rm -rf "${release_dir}"' EXIT
volume_dir="${release_dir}/volume"
mkdir -p "${volume_dir}/docs/assets"
ditto "${bundle_dir}" "${volume_dir}/BatteryBridge.app"
ln -s /Applications "${volume_dir}/Applications"
touch "${volume_dir}/.metadata_never_index"
cp "${project_dir}/README.md" "${volume_dir}/README.md"
cp "${project_dir}/docs/assets/logo.png" "${volume_dir}/docs/assets/logo.png"
python3 - "${project_dir}" "${volume_dir}/BatteryBridge-Source.zip" <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import sys
root=Path(sys.argv[1])
with ZipFile(sys.argv[2], 'w', ZIP_DEFLATED) as z:
    for name in ['Sources', 'tests', 'docs', 'README.md', 'build.sh', 'release.sh']:
        p=root/name
        files=sorted(p.rglob('*')) if p.is_dir() else [p]
        for f in files:
            if f.is_file():z.write(f, Path('BatteryBridge')/f.relative_to(root))
PY
hdiutil makehybrid -hfs -hfs-volume-name "BatteryBridge ${version} Preview" -o "${release_dir}/image.hfs" "${volume_dir}"
image_path="${output_dir}/BatteryBridge-${version}-preview.dmg"
hdiutil convert "${release_dir}/image.hfs.dmg" -format UDZO -o "${image_path}"
hdiutil verify "${image_path}"
# The release is the DMG. Do not retain an extra launchable application beside it.
rm -rf "${bundle_dir}"
printf '%s\n' "Release: ${image_path}"
