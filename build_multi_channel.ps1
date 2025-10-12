# 多渠道打包脚本
# 魅族：只打64位（arm64-v8a）
# 其他渠道：打64+32位通用包（arm64-v8a,armeabi-v7a）

$ErrorActionPreference = "Stop"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "多渠道打包脚本启动" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 定义渠道列表
$channels = @{
    "meizu" = "arm64-v8a"  # 魅族只打64位
    "yingyongbao" = "arm64-v8a,armeabi-v7a"  # 应用宝打通用包
    "huawei" = "arm64-v8a,armeabi-v7a"  # 华为打通用包
    "xiaomi" = "arm64-v8a,armeabi-v7a"  # 小米打通用包
    "oppo" = "arm64-v8a,armeabi-v7a"  # OPPO打通用包
    "vivo" = "arm64-v8a,armeabi-v7a"  # VIVO打通用包
}

# 创建输出目录
$outputDir = "multi_channel_apks"
if (Test-Path $outputDir) {
    Write-Host "清理旧的输出目录..." -ForegroundColor Yellow
    Remove-Item -Path $outputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $outputDir | Out-Null

# 记录成功和失败的渠道
$successChannels = @()
$failedChannels = @()

# 遍历每个渠道进行打包
foreach ($channel in $channels.Keys) {
    $targetAbi = $channels[$channel]
    
    Write-Host ""
    Write-Host "==================================" -ForegroundColor Green
    Write-Host "开始打包渠道: $channel" -ForegroundColor Green
    Write-Host "目标架构: $targetAbi" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    
    try {
        # 1. 修改 AndroidManifest.xml 中的渠道标识
        $manifestPath = "android\app\src\main\AndroidManifest.xml"
        Write-Host "步骤 1/3: 修改渠道标识为 $channel..." -ForegroundColor Cyan
        
        $manifestContent = Get-Content $manifestPath -Raw -Encoding UTF8
        $manifestContent = $manifestContent -replace 'android:value="[^"]*"(\s*android:name="UMENG_CHANNEL")', "android:value=`"$channel`"`$1"
        $manifestContent | Set-Content $manifestPath -Encoding UTF8 -NoNewline
        
        Write-Host "✓ 渠道标识修改成功" -ForegroundColor Green
        
        # 2. 清理并构建
        Write-Host ""
        Write-Host "步骤 2/3: 清理并构建 APK (架构: $targetAbi)..." -ForegroundColor Cyan
        
        # 先清理
        flutter clean | Out-Null
        
        # 根据架构参数选择构建命令
        if ($targetAbi -eq "arm64-v8a") {
            # 只打64位架构
            Write-Host "构建64位单架构APK..." -ForegroundColor Yellow
            flutter build apk --release --target-platform android-arm64
        } else {
            # 打通用包 (arm64-v8a + armeabi-v7a)
            Write-Host "构建通用APK (64+32位)..." -ForegroundColor Yellow
            flutter build apk --release
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter 构建失败"
        }
        
        Write-Host "✓ APK 构建成功" -ForegroundColor Green
        
        # 3. 复制并重命名 APK
        Write-Host ""
        Write-Host "步骤 3/3: 复制并重命名 APK..." -ForegroundColor Cyan
        
        $sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
        
        if (-not (Test-Path $sourceApk)) {
            throw "找不到构建的 APK: $sourceApk"
        }
        
        # 获取APK信息
        $apkSize = [math]::Round((Get-Item $sourceApk).Length / 1MB, 2)
        
        # 重命名格式：kissu_渠道名_架构.apk
        $abiSuffix = if ($targetAbi -eq "arm64-v8a") { "arm64" } else { "universal" }
        $targetApk = "$outputDir\kissu_${channel}_${abiSuffix}.apk"
        Copy-Item -Path $sourceApk -Destination $targetApk -Force
        
        Write-Host "✓ APK 已保存到: $targetApk ($apkSize MB)" -ForegroundColor Green
        
        $successChannels += "$channel ($abiSuffix)"
        
        Write-Host ""
        Write-Host "✓✓✓ 渠道 $channel 打包完成 ✓✓✓" -ForegroundColor Green
        
    } catch {
        Write-Host ""
        Write-Host "✗✗✗ 渠道 $channel 打包失败 ✗✗✗" -ForegroundColor Red
        Write-Host "错误信息: $_" -ForegroundColor Red
        $failedChannels += $channel
    }
}

# 打印汇总信息
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "多渠道打包完成汇总" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

if ($successChannels.Count -gt 0) {
    Write-Host "成功打包的渠道 ($($successChannels.Count)):" -ForegroundColor Green
    foreach ($channel in $successChannels) {
        Write-Host "  ✓ $channel" -ForegroundColor Green
    }
}

if ($failedChannels.Count -gt 0) {
    Write-Host ""
    Write-Host "失败的渠道 ($($failedChannels.Count)):" -ForegroundColor Red
    foreach ($channel in $failedChannels) {
        Write-Host "  ✗ $channel" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "所有 APK 已保存到: $outputDir\" -ForegroundColor Cyan

# 列出所有生成的APK
Write-Host ""
Write-Host "生成的APK文件列表:" -ForegroundColor Cyan
Get-ChildItem -Path $outputDir -Filter "*.apk" | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  - $($_.Name) ($size MB)" -ForegroundColor White
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "打包任务全部完成！" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

