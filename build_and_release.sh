#!/bin/bash
set -e

echo "Removing old build..."
rm -rf Build_Final_TA
rm -f Tuntaskilat-Pelanggan-Release.apk Tuntaskilat-Kru-Release.apk admin-web.zip release_note.txt

echo "Building Pelanggan app..."
cd apps/pelanggan
flutter build apk --release
cd ../..
cp apps/pelanggan/build/app/outputs/flutter-apk/app-release.apk ./Tuntaskilat-Pelanggan-Release.apk

echo "Building Kru app..."
cd apps/kru
flutter build apk --release
cd ../..
cp apps/kru/build/app/outputs/flutter-apk/app-release.apk ./Tuntaskilat-Kru-Release.apk

echo "Building Admin Web..."
cd apps/admin
flutter build web --release
cd ../..
cd apps/admin/build/web
zip -r ../../../../admin-web.zip .
cd ../../../..

echo "Creating release notes..."
cat << 'EOF' > release_note.txt
## Dev Build Updates
- Latest snapshot of the `dev` branch.
- Includes the newest changes for Pelanggan, Kru, and Admin apps.
- Built according to the project specifications.

**Apps included:**
- `Tuntaskilat-Pelanggan-Release.apk` (Android Release)
- `Tuntaskilat-Kru-Release.apk` (Android Release)
- `admin-web.zip` (Web Release)
EOF

echo "Creating GitHub Release..."
TAG_NAME="dev-$(date +%Y%m%d%H%M)"
gh release create $TAG_NAME Tuntaskilat-Pelanggan-Release.apk Tuntaskilat-Kru-Release.apk admin-web.zip --title "Dev Build $TAG_NAME" --notes-file release_note.txt

echo "Done!"
