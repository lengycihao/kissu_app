# Flutter multi-channel build script
# Usage: powershell -ExecutionPolicy Bypass -File .\build_channels.ps1
# Optional: powershell -ExecutionPolicy Bypass -File .\build_channels.ps1 -channels kissu_xiaomi,kissu_huawei

param(
    [string[]]$channels = @()
)

$allChannels = @(
    "kissu_xiaomi",
    "kissu_huawei",
    "kissu_rongyao",
    "kissu_vivo",
    "kissu_oppo",
    "kissu_meizu",
    "kissu_yyb",
    "kissu_wdj",
    "kissu_douyin"
)

# -File mode passes comma-separated values as a single string, split them
if ($channels.Count -eq 1 -and $channels[0].Contains(',')) {
    $channels = $channels[0].Split(',')
}
if ($channels.Count -eq 0) {
    $channels = $allChannels
}

$configFile = "lib\network\tools\config\app_configN.dart"
$apkSource = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
$outputDir = "build\channel_apks"

if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$originalContent = [System.IO.File]::ReadAllText($configFile, [System.Text.UTF8Encoding]::new($false))
$totalCount = $channels.Count
$successCount = 0
$failCount = 0
$startTime = Get-Date

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Flutter Channel Build - Total: $totalCount" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

for ($i = 0; $i -lt $channels.Count; $i++) {
    $channel = $channels[$i]
    $index = $i + 1
    $channelStart = Get-Date

    Write-Host ""
    Write-Host "[$index/$totalCount] Building: $channel ..." -ForegroundColor Yellow

    $content = [System.IO.File]::ReadAllText($configFile, [System.Text.UTF8Encoding]::new($false))
    $newValue = "static const String appChannel = '" + $channel + "';"
    $content = $content -replace "static const String appChannel = '.*?';", $newValue
    [System.IO.File]::WriteAllText($configFile, $content, [System.Text.UTF8Encoding]::new($false))

    flutter build apk --release --target-platform android-arm64 2>&1 | Out-Null

    if ($LASTEXITCODE -eq 0 -and (Test-Path $apkSource)) {
        $destApk = Join-Path $outputDir ($channel + ".apk")
        Copy-Item $apkSource $destApk -Force

        $elapsed = ((Get-Date) - $channelStart).ToString('mm\:ss')
        $fileSize = [math]::Round((Get-Item $destApk).Length / 1MB, 1)
        Write-Host ("[$index/$totalCount] $channel OK - " + $fileSize + "MB, " + $elapsed) -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "[$index/$totalCount] $channel FAILED!" -ForegroundColor Red
        $failCount++
    }
}

[System.IO.File]::WriteAllText($configFile, $originalContent, [System.Text.UTF8Encoding]::new($false))

$totalElapsed = ((Get-Date) - $startTime).ToString('hh\:mm\:ss')

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Done! Success: $successCount, Failed: $failCount" -ForegroundColor Cyan
Write-Host " Time: $totalElapsed" -ForegroundColor Cyan
Write-Host " Output: $outputDir" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($successCount -gt 0) {
    Write-Host ""
    Get-ChildItem $outputDir -Filter "*.apk" | ForEach-Object {
        $fileSize = [math]::Round($_.Length / 1MB, 1)
        Write-Host ("  " + $_.Name + " (" + $fileSize + "MB)") -ForegroundColor Gray
    }
}
