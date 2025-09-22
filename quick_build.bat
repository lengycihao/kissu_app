@echo off
chcp 65001 >nul
echo 快速打包脚本 - Kissu App
echo ================================

:: 渠道配置
set "CHANNELS=kissu_xiaomi kissu_huawei kissu_rongyao kissu_vivo kissu_oppo"
set "NAMES=小米 华为 荣耀 vivo oppo"

:: 创建输出目录
if not exist "build\apk" mkdir "build\apk"

:: 备份文件
copy "lib\network\interceptor\business_header_interceptor.dart" "business_header_interceptor.dart.bak" >nul

:: 开始打包
for %%c in (%CHANNELS%) do (
    echo.
    echo 正在打包: %%c
    
    :: 修改渠道
    powershell -Command "(Get-Content 'lib\network\interceptor\business_header_interceptor.dart') -replace '_cachedChannel \?\?= Platform\.isAndroid \? ''kissu_oppo'' : ''Android'';', '_cachedChannel ??= Platform.isAndroid ? ''%%c'' : ''Android'';' | Set-Content 'lib\network\interceptor\business_header_interceptor.dart'"
    
    :: 构建
    flutter clean >nul 2>&1
    flutter pub get >nul 2>&1
    flutter build apk --target-platform android-arm,android-arm64 --release >nul 2>&1
    
    :: 重命名
    if exist "build\app\outputs\flutter-apk\app-release.apk" (
        copy "build\app\outputs\flutter-apk\app-release.apk" "build\apk\%%c.apk" >nul
        echo ✓ %%c 完成
    ) else (
        echo ✗ %%c 失败
    )
)

:: 恢复文件
copy "business_header_interceptor.dart.bak" "lib\network\interceptor\business_header_interceptor.dart" >nul
del "business_header_interceptor.dart.bak" >nul

echo.
echo 打包完成！文件位置: build\apk\
dir /b "build\apk\*.apk"
pause

