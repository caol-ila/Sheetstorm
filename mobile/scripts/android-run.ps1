# Startet den Sheetstorm-Test-AVD und installiert die Debug-APK.
$ErrorActionPreference = 'Stop'
$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }

$emu = Get-Process -Name "qemu-system-*" -ErrorAction SilentlyContinue
if (-not $emu) {
  Write-Host "Starte Emulator (AVD: sheetstorm-test) …"
  Start-Process -FilePath "$sdk\emulator\emulator.exe" -ArgumentList "-avd","sheetstorm-test","-no-snapshot-load" -WindowStyle Minimized
  & "$sdk\platform-tools\adb.exe" wait-for-device
  Start-Sleep -Seconds 8
}

$proj = Resolve-Path "$PSScriptRoot\..\.."
Push-Location "$proj\mobile"
npm run build:www
npx cap sync android
Push-Location "android"
.\gradlew.bat installDebug
Pop-Location
& "$sdk\platform-tools\adb.exe" shell am start -n de.sheetstorm.app/.MainActivity
Pop-Location
Write-Host "✓ App auf Emulator installiert."
