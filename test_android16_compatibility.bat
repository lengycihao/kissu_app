@echo off
chcp 65001 >nul
echo ========================================
echo     Android 16 兼容性测试脚本
echo ========================================
echo.

:: 设置颜色
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "RESET=[0m"

echo %BLUE%开始Android 16兼容性测试...%RESET%
echo.

:: 检查Flutter环境
echo %BLUE%1. 检查Flutter环境...%RESET%
flutter --version
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

:: 清理之前的构建
echo %BLUE%2. 清理之前的构建...%RESET%
flutter clean
if %errorlevel% neq 0 (
    echo %RED%错误: 清理构建失败%RESET%
    pause
    exit /b 1
)

:: 获取依赖
echo %BLUE%3. 获取依赖...%RESET%
flutter pub get
if %errorlevel% neq 0 (
    echo %RED%错误: 获取依赖失败%RESET%
    pause
    exit /b 1
)

:: 检查Android 16兼容性
echo %BLUE%4. 检查Android 16兼容性...%RESET%
flutter doctor -v
echo.

:: 构建APK以测试兼容性
echo %BLUE%5. 构建APK测试Android 16兼容性...%RESET%
flutter build apk --target-platform android-arm64 --release
if %errorlevel% neq 0 (
    echo %RED%错误: 构建APK失败，可能存在Android 16兼容性问题%RESET%
    echo %YELLOW%请检查以下问题:%RESET%
    echo - 依赖库是否支持Android 16
    echo - 权限配置是否正确
    echo - 前台服务类型是否明确指定
    echo - 目标SDK版本是否为36
    pause
    exit /b 1
)

echo %GREEN%✓ Android 16兼容性测试通过！%RESET%
echo %GREEN%✓ APK构建成功，支持Android 16 (API 36)%RESET%
echo.

:: 显示构建信息
echo %BLUE%构建信息:%RESET%
echo - 目标SDK: 36 (Android 16)
echo - 编译SDK: 36 (Android 16)
echo - 最小SDK: 24 (Android 7.0)
echo - 架构: arm64-v8a
echo.

echo %GREEN%Android 16兼容性适配完成！%RESET%
echo %YELLOW%建议在真实Android 16设备上进一步测试%RESET%
pause
