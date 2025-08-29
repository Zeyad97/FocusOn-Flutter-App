@echo off
echo.
echo 🎵 MUSIC APP ICON GENERATOR
echo ============================
echo.
echo Your app still shows the Flutter logo because we need to:
echo 1. Convert SVG to PNG (1024x1024)
echo 2. Run the icon generator
echo.
echo STEP 1: Convert SVG to PNG
echo -------------------------
echo Go to: https://cloudconvert.com/svg-to-png
echo Upload: assets\images\app_icon_temp.svg
echo Set size: 1024x1024 pixels
echo Download as: app_icon_1024.png
echo Place in project root folder (same as pubspec.yaml)
echo.
echo STEP 2: Generate App Icons
echo -------------------------
echo flutter pub run flutter_launcher_icons:main
echo.
echo Your purple music note icon will then replace the Flutter logo!
echo.
pause
