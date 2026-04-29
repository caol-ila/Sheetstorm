# Patcht MainActivity.java, dass das BLE-Plugin registriert wird.
# Aufruf nach `npx cap add android` einmalig.
$ErrorActionPreference = 'Stop'
$path = Join-Path $PSScriptRoot "..\android\app\src\main\java\de\sheetstorm\app\MainActivity.java"
if (-not (Test-Path $path)) { Write-Error "MainActivity.java nicht gefunden — npx cap add android zuerst ausfuehren." }

$src = Get-Content $path -Raw

if ($src -match "registerPlugin\(SheetstormBleAdvertiserPlugin\.class\);") {
  Write-Host "✓ Plugin-Registrierung schon vorhanden."
  return
}

# import
if ($src -notmatch "import de\.sheetstorm\.app\.SheetstormBleAdvertiserPlugin;") {
  $src = $src -replace "(package de\.sheetstorm\.app;\s*\r?\n)", "`$1`r`nimport de.sheetstorm.app.SheetstormBleAdvertiserPlugin;`r`n"
}

# registerPlugin vor super.onCreate
$src = $src -replace "(\s+)super\.onCreate\(savedInstanceState\);", '${1}registerPlugin(SheetstormBleAdvertiserPlugin.class);${1}super.onCreate(savedInstanceState);'

Set-Content $path $src -Encoding UTF8

# AndroidManifest-Permissions ergaenzen
$manifest = Join-Path $PSScriptRoot "..\android\app\src\main\AndroidManifest.xml"
$m = Get-Content $manifest -Raw
$perms = @"
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
"@
foreach ($p in $perms -split "`r?`n") {
  if ($p -and $m -notmatch [regex]::Escape($p)) {
    $m = $m -replace '(<manifest[^>]*>\s*)', "`$1$p`r`n    "
  }
}
Set-Content $manifest $m -Encoding UTF8

Write-Host "✓ MainActivity.java gepatcht und Manifest-Permissions ergaenzt."
