# 单渠道测试脚本
param(
    [string]$channel = "meizu",
    [string]$abi = "arm64-v8a"
)

$ErrorActionPreference = "Stop"

Write-Host "测试打包: $channel (架构: $abi)" -ForegroundColor Cyan

# 修改渠道
$manifestPath = "android\app\src\main\AndroidManifest.xml"
$manifestContent = Get-Content $manifestPath -Raw -Encoding UTF8
$manifestContent = $manifestContent -replace 'android:value="[^"]*"(\s*android:name="UMENG_CHANNEL")', "android:value=`"$channel`"`$1"
$manifestContent | Set-Content $manifestPath -Encoding UTF8 -NoNewline

Write-Host "渠道已设置为: $channel" -ForegroundColor Green

# 清理
Write-Host "清理旧构建..." -ForegroundColor Yellow
flutter clean

# 构建
Write-Host "开始构建APK (架构: $abi)..." -ForegroundColor Yellow

# 注意：build.gradle.kts 中已硬编码只打 arm64-v8a 架构
flutter build apk --release --target-platform android-arm64

if ($LASTEXITCODE -eq 0) {
    Write-Host "构建成功！" -ForegroundColor Green
    
    # 显示生成的APK
    Write-Host "`n生成的APK:" -ForegroundColor Cyan
    Get-ChildItem build\app\outputs\flutter-apk\*.apk | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  $($_.Name): $size MB" -ForegroundColor White
    }
} else {
    Write-Host "构建失败！" -ForegroundColor Red
    exit 1
}

