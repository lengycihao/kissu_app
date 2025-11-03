# Multi-channel build script for Kissu App
# Build arm64 APKs by modifying business_header_interceptor.dart

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Multi-channel Build Script Started" -ForegroundColor Cyan
Write-Host "Building arm64 APKs for 6 channels" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Channel list
$channels = @("kissu_xiaomi", "kissu_huawei", "kissu_rongyao", "kissu_vivo", "kissu_oppo", "kissu_yyb")

# Create output directory with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "release_apks_$timestamp"
Write-Host "Output Directory: $outputDir" -ForegroundColor Cyan

if (Test-Path $outputDir) {
    Write-Host "Cleaning old output directory..." -ForegroundColor Yellow
    Remove-Item -Path $outputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $outputDir | Out-Null

# Target file path
$headerFilePath = "lib\network\interceptor\business_header_interceptor.dart"

# Backup original file
Write-Host "Backing up original file..." -ForegroundColor Yellow
$backupPath = "$headerFilePath.backup"
Copy-Item -Path $headerFilePath -Destination $backupPath -Force

# Track success and failures
$successChannels = @()
$failedChannels = @()

try {
    # Build each channel
    foreach ($channelId in $channels) {
        Write-Host ""
        Write-Host "==================================" -ForegroundColor Green
        Write-Host "Building Channel: $channelId" -ForegroundColor Green
        Write-Host "Target: arm64 only" -ForegroundColor Green
        Write-Host "==================================" -ForegroundColor Green
        Write-Host ""
        
        try {
            # Step 1: Modify business_header_interceptor.dart
            Write-Host "Step 1/3: Update channel to $channelId..." -ForegroundColor Cyan
            
            $content = Get-Content $headerFilePath -Raw -Encoding UTF8
            # Replace the default channel value on line 192
            $content = $content -replace "Platform\.isAndroid \? '([^']+)' : 'kissu_default'", "Platform.isAndroid ? '$channelId' : 'kissu_default'"
            $content | Set-Content $headerFilePath -Encoding UTF8 -NoNewline
            
            Write-Host "Success: Channel updated to $channelId" -ForegroundColor Green
            
            # Step 2: Clean and build arm64 APK
            Write-Host ""
            Write-Host "Step 2/3: Building arm64 APK..." -ForegroundColor Cyan
            
            flutter clean | Out-Null
            flutter build apk --release --target-platform android-arm64
            
            if ($LASTEXITCODE -ne 0) {
                throw "Flutter build failed"
            }
            
            Write-Host "Success: APK built" -ForegroundColor Green
            
            # Step 3: Copy and rename APK
            Write-Host ""
            Write-Host "Step 3/3: Copy and rename APK..." -ForegroundColor Cyan
            
            $sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
            
            if (-not (Test-Path $sourceApk)) {
                throw "APK not found: $sourceApk"
            }
            
            # Get APK size
            $apkSize = [math]::Round((Get-Item $sourceApk).Length / 1MB, 2)
            
            # Target name: channelId.apk
            $targetApk = "$outputDir\${channelId}.apk"
            Copy-Item -Path $sourceApk -Destination $targetApk -Force
            
            $sizeText = "$apkSize" + "MB"
            Write-Host "Success: APK saved to $targetApk ($sizeText)" -ForegroundColor Green
            
            $successChannels += $channelId
            
            Write-Host ""
            Write-Host "Channel $channelId build complete!" -ForegroundColor Green
            
        } catch {
            Write-Host ""
            Write-Host "Channel $channelId build failed!" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            $failedChannels += $channelId
        }
        
        # Restore original file for next channel
        Copy-Item -Path $backupPath -Destination $headerFilePath -Force
    }
} finally {
    # Always restore original file
    Write-Host ""
    Write-Host "Restoring original file..." -ForegroundColor Yellow
    if (Test-Path $backupPath) {
        Copy-Item -Path $backupPath -Destination $headerFilePath -Force
        Remove-Item -Path $backupPath -Force
        Write-Host "Original file restored" -ForegroundColor Green
    }
}

# Print summary
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Build Summary" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

if ($successChannels.Count -gt 0) {
    Write-Host "Successful channels: $($successChannels.Count)" -ForegroundColor Green
    foreach ($channel in $successChannels) {
        Write-Host "  Success: $channel" -ForegroundColor Green
    }
}

if ($failedChannels.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed channels: $($failedChannels.Count)" -ForegroundColor Red
    foreach ($channel in $failedChannels) {
        Write-Host "  Failed: $channel" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "All APKs saved to: $outputDir\" -ForegroundColor Cyan

# List all generated APKs
Write-Host ""
Write-Host "Generated APK files:" -ForegroundColor Cyan
Get-ChildItem -Path $outputDir -Filter "*.apk" | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    $sizeInfo = "$sizeMB" + "MB"
    Write-Host "  - $($_.Name) ($sizeInfo)" -ForegroundColor White
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "All builds completed!" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
