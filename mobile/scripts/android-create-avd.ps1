# Erstellt einen Android-Emulator-AVD fuer Sheetstorm-Tests
$ErrorActionPreference = 'Stop'
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
if (-not (Test-Path $sdk)) {
  Write-Error "Android SDK nicht gefunden unter $sdk. Setze ANDROID_HOME oder installiere Android Studio."
}
$cmdline = "$sdk\cmdline-tools\latest\bin"
& "$cmdline\sdkmanager.bat" --install "platforms;android-34" "system-images;android-34;google_apis;x86_64" "build-tools;34.0.0"
"no" | & "$cmdline\avdmanager.bat" create avd -n sheetstorm-test -k "system-images;android-34;google_apis;x86_64" --force
Write-Host "✓ AVD 'sheetstorm-test' erstellt."
