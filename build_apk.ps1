# Kissu App 自动打包脚本 (PowerShell版本)
# 支持5个渠道: 小米、华为、荣耀、vivo、oppo

param(
    [switch]$SkipClean,
    [switch]$Verbose
)

# 设置控制台编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 颜色函数
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

# 定义渠道配置
$channels = @{
    "kissu_xiaomi" = "小米"
    "kissu_huawei" = "华为"
    "kissu_rongyao" = "荣耀"
    "kissu_vivo" = "vivo"
    "kissu_oppo" = "oppo"
}

Write-ColorText "========================================" "Cyan"
Write-ColorText "          Kissu App 自动打包脚本" "Cyan"
Write-ColorText "========================================" "Cyan"
Write-Host ""

# 检查Flutter环境
Write-ColorText "检查Flutter环境..." "Blue"
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter未找到"
    }
    Write-ColorText "✓ Flutter环境正常" "Green"
} catch {
    Write-ColorText "错误: 未找到Flutter，请确保Flutter已安装并添加到PATH" "Red"
    Read-Host "按回车键退出"
    exit 1
}

# 检查项目目录
if (-not (Test-Path "lib\network\interceptor\business_header_interceptor.dart")) {
    Write-ColorText "错误: 请在项目根目录运行此脚本" "Red"
    Read-Host "按回车键退出"
    exit 1
}

# 创建输出目录
$outputDir = "build\apk"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 备份原始文件
$originalFile = "lib\network\interceptor\business_header_interceptor.dart"
$backupFile = "$originalFile.backup"
Write-ColorText "备份原始文件..." "Yellow"
Copy-Item $originalFile $backupFile -Force

try {
    # 开始打包每个渠道
    foreach ($channel in $channels.Keys) {
        $channelName = $channels[$channel]
        
        Write-Host ""
        Write-ColorText "========================================" "Green"
        Write-ColorText "开始打包渠道: $channel ($channelName)" "Green"
        Write-ColorText "========================================" "Green"
        
        # 修改渠道名
        Write-ColorText "修改渠道名为: $channel" "Blue"
        $content = Get-Content $originalFile -Raw
        $pattern = '_cachedChannel \?\?= Platform\.isAndroid \? ''kissu_oppo'' : ''Android'';'
        $replacement = "_cachedChannel ??= Platform.isAndroid ? '$channel' : 'Android';"
        $content = $content -replace $pattern, $replacement
        Set-Content $originalFile $content -Encoding UTF8
        
        if ($Verbose) {
            Write-ColorText "渠道名修改完成" "Green"
        }
        
        # 清理之前的构建
        if (-not $SkipClean) {
            Write-ColorText "清理之前的构建..." "Blue"
            flutter clean 2>$null | Out-Null
        }
        
        # 获取依赖
        Write-ColorText "获取依赖..." "Blue"
        flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw "获取依赖失败"
        }
        
        # 开始构建APK
        Write-ColorText "开始构建APK..." "Blue"
        if ($Verbose) {
            flutter build apk --target-platform android-arm,android-arm64 --release
        } else {
            flutter build apk --target-platform android-arm,android-arm64 --release 2>$null | Out-Null
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "构建APK失败"
        }
        
        # 重命名APK文件
        $sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
        $targetApk = "$outputDir\kissu_${channel}_${channelName}.apk"
        
        if (Test-Path $sourceApk) {
            Copy-Item $sourceApk $targetApk -Force
            Write-ColorText "✓ 渠道 $channel 打包成功: $targetApk" "Green"
        } else {
            Write-ColorText "✗ 未找到生成的APK文件: $sourceApk" "Red"
        }
    }
    
    Write-Host ""
    Write-ColorText "========================================" "Green"
    Write-ColorText "所有渠道打包完成！" "Green"
    Write-ColorText "========================================" "Green"
    Write-Host ""
    
    # 显示生成的APK文件
    Write-ColorText "生成的APK文件:" "Blue"
    $apkFiles = Get-ChildItem "$outputDir\*.apk" -ErrorAction SilentlyContinue
    if ($apkFiles) {
        foreach ($apk in $apkFiles) {
            $size = [math]::Round($apk.Length / 1MB, 2)
            Write-ColorText "  $($apk.Name) (${size}MB)" "White"
        }
    } else {
        Write-ColorText "  未找到APK文件" "Yellow"
    }
    
} catch {
    Write-ColorText "发生错误: $($_.Exception.Message)" "Red"
    Write-ColorText "恢复原始文件..." "Yellow"
} finally {
    # 恢复原始文件
    if (Test-Path $backupFile) {
        Copy-Item $backupFile $originalFile -Force
        Remove-Item $backupFile -Force
        Write-ColorText "原始文件已恢复" "Green"
    }
}

Write-Host ""
Write-ColorText "脚本执行完成！" "Green"
Read-Host "按回车键退出"

