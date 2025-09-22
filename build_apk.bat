@echo off
chcp 65001 >nul
echo ========================================
echo          Kissu App 自动打包脚本
echo ========================================
echo.

:: 设置颜色
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "RESET=[0m"

:: 定义渠道配置
set "CHANNELS=kissu_xiaomi kissu_huawei kissu_rongyao kissu_vivo kissu_oppo"
set "CHANNEL_NAMES=小米 华为 荣耀 vivo oppo"

:: 检查Flutter环境
echo %BLUE%检查Flutter环境...%RESET%
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%错误: 未找到Flutter，请确保Flutter已安装并添加到PATH%RESET%
    pause
    exit /b 1
)

:: 检查项目目录
if not exist "lib\network\interceptor\business_header_interceptor.dart" (
    echo %RED%错误: 请在项目根目录运行此脚本%RESET%
    pause
    exit /b 1
)

:: 创建输出目录
if not exist "build\apk" mkdir "build\apk"

:: 备份原始文件
echo %YELLOW%备份原始文件...%RESET%
copy "lib\network\interceptor\business_header_interceptor.dart" "lib\network\interceptor\business_header_interceptor.dart.backup" >nul

:: 开始打包
set "CHANNEL_INDEX=1"
for %%c in (%CHANNELS%) do (
    echo.
    echo %GREEN%========================================%RESET%
    echo %GREEN%开始打包渠道: %%c%RESET%
    echo %GREEN%========================================%RESET%
    
    :: 修改渠道名
    echo %BLUE%修改渠道名为: %%c%RESET%
    powershell -Command "(Get-Content 'lib\network\interceptor\business_header_interceptor.dart') -replace '_cachedChannel \?\?= Platform\.isAndroid \? ''kissu_oppo'' : ''Android'';', '_cachedChannel ??= Platform.isAndroid ? ''%%c'' : ''Android'';' | Set-Content 'lib\network\interceptor\business_header_interceptor.dart'"
    
    if %errorlevel% neq 0 (
        echo %RED%错误: 修改渠道名失败%RESET%
        goto :restore_and_exit
    )
    
    :: 清理之前的构建
    echo %BLUE%清理之前的构建...%RESET%
    flutter clean >nul 2>&1
    
    :: 获取依赖
    echo %BLUE%获取依赖...%RESET%
    flutter pub get
    
    if %errorlevel% neq 0 (
        echo %RED%错误: 获取依赖失败%RESET%
        goto :restore_and_exit
    )
    
    :: 开始构建APK
    echo %BLUE%开始构建APK...%RESET%
    flutter build apk --target-platform android-arm,android-arm64 --release
    
    if %errorlevel% neq 0 (
        echo %RED%错误: 构建APK失败%RESET%
        goto :restore_and_exit
    )
    
    :: 重命名APK文件
    set "CHANNEL_NAME="
    call :get_channel_name %%c
    set "NEW_NAME=build\apk\kissu_%%c_%CHANNEL_NAME%.apk"
    
    echo %BLUE%重命名APK文件为: %NEW_NAME%%RESET%
    if exist "build\app\outputs\flutter-apk\app-release.apk" (
        copy "build\app\outputs\flutter-apk\app-release.apk" "%NEW_NAME%" >nul
        if %errorlevel% equ 0 (
            echo %GREEN%✓ 渠道 %%c 打包成功: %NEW_NAME%%RESET%
        ) else (
            echo %RED%✗ 重命名APK文件失败%RESET%
        )
    ) else (
        echo %RED%✗ 未找到生成的APK文件%RESET%
    )
    
    set /a CHANNEL_INDEX+=1
)

echo.
echo %GREEN%========================================%RESET%
echo %GREEN%所有渠道打包完成！%RESET%
echo %GREEN%========================================%RESET%
echo.
echo %BLUE%生成的APK文件位置:%RESET%
dir /b "build\apk\*.apk" 2>nul
echo.

:: 恢复原始文件
echo %YELLOW%恢复原始文件...%RESET%
copy "lib\network\interceptor\business_header_interceptor.dart.backup" "lib\network\interceptor\business_header_interceptor.dart" >nul
del "lib\network\interceptor\business_header_interceptor.dart.backup" >nul

echo %GREEN%打包完成！%RESET%
pause
exit /b 0

:get_channel_name
if "%1"=="kissu_xiaomi" set "CHANNEL_NAME=小米"
if "%1"=="kissu_huawei" set "CHANNEL_NAME=华为"
if "%1"=="kissu_rongyao" set "CHANNEL_NAME=荣耀"
if "%1"=="kissu_vivo" set "CHANNEL_NAME=vivo"
if "%1"=="kissu_oppo" set "CHANNEL_NAME=oppo"
goto :eof

:restore_and_exit
echo %RED%发生错误，恢复原始文件...%RESET%
if exist "lib\network\interceptor\business_header_interceptor.dart.backup" (
    copy "lib\network\interceptor\business_header_interceptor.dart.backup" "lib\network\interceptor\business_header_interceptor.dart" >nul
    del "lib\network\interceptor\business_header_interceptor.dart.backup" >nul
)
echo %RED%打包失败！%RESET%
pause
exit /b 1

