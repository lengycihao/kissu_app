# Multi-Channel APK Build Script
# Channels: Xiaomi, Huawei, Rongyao, Vivo, Oppo, Meizu, YYB
# Meizu: 64-bit only | Others: 32-bit + 64-bit

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Kissu App Multi-Channel Build Tool" -ForegroundColor Cyan
Write-Host "   Meizu: 64-bit | Others: 32+64-bit" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define channel list
$channels = @(
    @{name="kissu_xiaomi"; desc="Xiaomi"},
    @{name="kissu_huawei"; desc="Huawei"},
    @{name="kissu_rongyao"; desc="Rongyao"},
    @{name="kissu_vivo"; desc="Vivo"},
    @{name="kissu_oppo"; desc="Oppo"},
    @{name="kissu_meizu"; desc="Meizu"},
    @{name="kissu_yyb"; desc="YYB"}
)

# Target file
$targetFile = "lib\network\interceptor\business_header_interceptor.dart"
$backupFile = "lib\network\interceptor\business_header_interceptor.dart.backup"

# Create output directory (use absolute path to ensure it exists)
$outputDir = Join-Path (Get-Location) "multi_channel_apks"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
Write-Host "[OUTPUT] APK output directory: $outputDir" -ForegroundColor Cyan

# Backup original file
Write-Host "[BACKUP] Backing up original file..." -ForegroundColor Yellow
Copy-Item $targetFile $backupFile -Force

# Clean build cache ONCE before starting
Write-Host "[CLEAN] Cleaning build cache (once)..." -ForegroundColor Yellow
flutter clean | Out-Null

# Record start time
$startTime = Get-Date

# Loop through each channel
$successCount = 0
$failCount = 0

foreach ($channel in $channels) {
    $channelName = $channel.name
    $channelDesc = $channel.desc
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Building: $channelDesc ($channelName)" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
    # Read file content
    $content = Get-Content $targetFile -Raw -Encoding UTF8
    
    # Replace channel configuration (around line 191)
    # Original: _cachedChannel ??= Platform.isAndroid ? 'kissu_yyb' : 'Android';
    # Target: _cachedChannel ??= Platform.isAndroid ? '$channelName' : 'Android';
    $pattern = "(_cachedChannel \?\?= Platform\.isAndroid \? ')(kissu_[a-z]+)(' : 'Android';)"
    $replacement = "`${1}$channelName`${3}"
    
    $newContent = $content -replace $pattern, $replacement
    
    # Save modified file
    $newContent | Set-Content $targetFile -Encoding UTF8 -NoNewline
    
    Write-Host "[CONFIG] Channel updated: $channelName" -ForegroundColor Cyan
    
    # Determine build parameters based on channel
    if ($channelName -eq "kissu_meizu") {
        # Meizu: Only 64-bit (smaller size)
        $buildPlatform = "android-arm64"
        $buildDesc = "64-bit only"
        $apkSuffix = "arm64"
    } else {
        # Others: 32-bit + 64-bit universal APK (larger size)
        $buildPlatform = "android-arm,android-arm64"
        $buildDesc = "32+64-bit universal"
        $apkSuffix = "universal"
    }
    
    Write-Host "[BUILD] Building $buildDesc APK..." -ForegroundColor Yellow
    
    $buildResult = flutter build apk --release --target-platform $buildPlatform 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Build completed!" -ForegroundColor Green
        
        # Copy APK to output directory and rename IMMEDIATELY
        $sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
        $destApk = Join-Path $outputDir "kissu_${channelName}_${apkSuffix}.apk"
        
        if (Test-Path $sourceApk) {
            Copy-Item $sourceApk $destApk -Force
            
            # Get file size
            $fileSize = [math]::Round((Get-Item $destApk).Length / 1MB, 2)
            
            Write-Host "[APK] Saved to: $destApk (Size: $fileSize MB)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "[ERROR] APK file not found" -ForegroundColor Red
            $failCount++
        }
    } else {
        Write-Host "[ERROR] Build failed!" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
        $failCount++
    }
}

# Restore original file
Write-Host ""
Write-Host "[RESTORE] Restoring original configuration..." -ForegroundColor Yellow
Copy-Item $backupFile $targetFile -Force
Remove-Item $backupFile -Force

# Record end time
$endTime = Get-Date
$duration = $endTime - $startTime

# Print summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Build Completed!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Successful builds: $successCount channels" -ForegroundColor Green
Write-Host "[FAILED] Failed builds: $failCount channels" -ForegroundColor Red
Write-Host "[TIME] Total duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
Write-Host ""
Write-Host "[OUTPUT] APK location: $outputDir" -ForegroundColor Cyan
Write-Host ""

# List generated APK files
if (Test-Path $outputDir) {
    Write-Host "Generated APK files:" -ForegroundColor Green
    $apkFiles = Get-ChildItem $outputDir -Filter "*.apk" -ErrorAction SilentlyContinue
    if ($apkFiles) {
        foreach ($file in $apkFiles) {
            $size = [math]::Round($file.Length / 1MB, 2)
            Write-Host "  - $($file.Name) ($size MB)" -ForegroundColor White
        }
    } else {
        Write-Host "  No APK files found!" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[DONE] All channels completed!" -ForegroundColor Green
