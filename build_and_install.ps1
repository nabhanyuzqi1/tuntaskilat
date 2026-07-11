# Tuntaskilat — build 2 APK + install ke 2 emulator (jalankan di terminal Anda)
$ErrorActionPreference = "Stop"
$env:Path = "C:\flutter\bin;$env:LOCALAPPDATA\Android\Sdk\platform-tools;$env:Path"
$repo = "C:\Users\MANOB_PC2\Documents\GitHub\tuntaskilat"
$adb  = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

Write-Host "== 1/5 Boot emulator kedua (Tuntas_Pelanggan) bila belum jalan =="
$running = & $adb devices | Select-String "emulator-"
if (($running | Measure-Object).Count -lt 2) {
  Start-Process -FilePath "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -ArgumentList "-avd","Tuntas_Pelanggan"
  Write-Host "   menunggu emulator kedua boot..."
  Start-Sleep -Seconds 45
}
& $adb devices

Write-Host "== 2/5 Build APK KRU =="
Set-Location "$repo\apps\kru";       flutter build apk --debug
Write-Host "== 3/5 Build APK PELANGGAN =="
Set-Location "$repo\apps\pelanggan"; flutter build apk --debug

# Peta: emulator pertama = kru, kedua = pelanggan
$devs = (& $adb devices | Select-String "emulator-\d+" | ForEach-Object { ($_ -split "\s+")[0] })
$kruDev = $devs[0]; $pelDev = if ($devs.Count -gt 1) { $devs[1] } else { $devs[0] }
Write-Host "== 4/5 Install KRU -> $kruDev =="
& $adb -s $kruDev install -r "$repo\apps\kru\build\app\outputs\flutter-apk\app-debug.apk"
Write-Host "== 5/5 Install PELANGGAN -> $pelDev =="
& $adb -s $pelDev install -r "$repo\apps\pelanggan\build\app\outputs\flutter-apk\app-debug.apk"

Write-Host ""
Write-Host "SELESAI. kru=$kruDev  pelanggan=$pelDev" -ForegroundColor Green
Write-Host "Balas ke Claude: 'apk siap, kru=$kruDev pelanggan=$pelDev'"
