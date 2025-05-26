@echo off
chcp 65001 >nul

if "%~1"=="" (
    echo 使用方法:
    echo 1. 将wxapkg文件拖拽到此批处理文件上
    echo 2. 或者双击运行此文件，然后输入文件路径
    echo.
    
    set /p "WXAPKG_PATH=请输入wxapkg文件路径: "
    if "!WXAPKG_PATH!"=="" (
        echo 未输入文件路径，退出...
        pause
        exit /b 1
    )
) else (
    set "WXAPKG_PATH=%~1"
)

REM 调用PowerShell脚本
powershell.exe -ExecutionPolicy Bypass -File "%~dp0wxapkg_processor.ps1" -WxapkgPath "%WXAPKG_PATH%"

pause 