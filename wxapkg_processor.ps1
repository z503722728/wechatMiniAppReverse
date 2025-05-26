param(
    [Parameter(Mandatory=$true)]
    [string]$WxapkgPath
)

# 设置控制台编码为UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 提取和分类native资源文件的函数
function Extract-NativeResources {
    param(
        [string]$UnpackDir,
        [string]$OutputDir
    )
    
    Write-Host ""
    Write-Host "步骤3: 提取和分类native资源文件..." -ForegroundColor Yellow
    
    # 查找native目录
    $NativeDir = Join-Path $UnpackDir "subpackages\resources\native"
    
    if (-not (Test-Path $NativeDir)) {
        Write-Host "⚠️  未找到native目录: $NativeDir" -ForegroundColor Yellow
        return
    }
    
    Write-Host "找到native目录: $NativeDir" -ForegroundColor Green
    
    # 创建分类目录 - 直接在输出根目录下创建extracted_resources文件夹
    $ResourcesDir = Join-Path $OutputDir "extracted_resources"
    $ImagesDir = Join-Path $ResourcesDir "images"
    $AudioDir = Join-Path $ResourcesDir "audio"
    $VideoDir = Join-Path $ResourcesDir "video"
    $OtherDir = Join-Path $ResourcesDir "other"
    
    # 创建目录
    @($ResourcesDir, $ImagesDir, $AudioDir, $VideoDir, $OtherDir) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    # 定义文件类型映射
    $FileTypeMap = @{
        "Images" = @(".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".svg", ".ico")
        "Audio" = @(".mp3", ".wav", ".aac", ".ogg", ".m4a", ".flac", ".wma")
        "Video" = @(".mp4", ".avi", ".mov", ".wmv", ".flv", ".mkv", ".webm")
    }
    
    # 获取所有文件
    $AllFiles = Get-ChildItem -Path $NativeDir -File -Recurse
    $TotalFiles = $AllFiles.Count
    
    if ($TotalFiles -eq 0) {
        Write-Host "⚠️  native目录中没有找到文件" -ForegroundColor Yellow
        return
    }
    
    Write-Host "找到 $TotalFiles 个文件，开始分类..." -ForegroundColor Cyan
    
    # 分类计数器
    $Counters = @{
        "Images" = 1
        "Audio" = 1
        "Video" = 1
        "Other" = 1
    }
    
    # 统计信息
    $Stats = @{
        "Images" = 0
        "Audio" = 0
        "Video" = 0
        "Other" = 0
    }
    
    foreach ($File in $AllFiles) {
        $Extension = $File.Extension.ToLower()
        $Category = "Other"
        $TargetDir = $OtherDir
        
        # 确定文件类型
        foreach ($Type in $FileTypeMap.Keys) {
            if ($FileTypeMap[$Type] -contains $Extension) {
                $Category = $Type
                switch ($Type) {
                    "Images" { $TargetDir = $ImagesDir }
                    "Audio" { $TargetDir = $AudioDir }
                    "Video" { $TargetDir = $VideoDir }
                }
                break
            }
        }
        
        # 生成新文件名
        $Counter = $Counters[$Category]
        $NewFileName = "{0:D4}_{1}{2}" -f $Counter, $Category.ToLower(), $Extension
        $TargetPath = Join-Path $TargetDir $NewFileName
        
        try {
            # 复制文件
            Copy-Item -Path $File.FullName -Destination $TargetPath -Force
            $Stats[$Category]++
            $Counters[$Category]++
            
            Write-Host "  [$Category] $($File.Name) -> $NewFileName" -ForegroundColor Gray
        }
        catch {
            Write-Host "  ❌ 复制失败: $($File.Name) - $_" -ForegroundColor Red
        }
    }
    
    # 显示统计信息
    Write-Host ""
    Write-Host "📊 资源文件分类完成:" -ForegroundColor Green
    Write-Host "  🖼️  图片文件: $($Stats.Images) 个" -ForegroundColor Cyan
    Write-Host "  🎵 音频文件: $($Stats.Audio) 个" -ForegroundColor Cyan
    Write-Host "  🎬 视频文件: $($Stats.Video) 个" -ForegroundColor Cyan
    Write-Host "  📄 其他文件: $($Stats.Other) 个" -ForegroundColor Cyan
    Write-Host "  📁 资源目录: $ResourcesDir" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "微信小程序一键解密解包工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查文件是否存在
if (-not (Test-Path $WxapkgPath)) {
    Write-Host "错误: 文件不存在: $WxapkgPath" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

Write-Host "文件路径: $WxapkgPath" -ForegroundColor Green
Write-Host ""

# 尝试从路径中提取微信小程序ID
$AutoWxId = ""
if ($WxapkgPath -match "\\Applet\\([^\\]+)") {
    $AutoWxId = $Matches[1]
    Write-Host "✅ 自动检测到微信小程序ID: $AutoWxId" -ForegroundColor Green
    # $confirm = Read-Host "是否使用此ID? (直接回车确认，输入n手动输入)"
    
    # if ($confirm -eq "n") {
    #     $WxId = Read-Host "请输入微信小程序ID"
    #     if ([string]::IsNullOrEmpty($WxId)) {
    #         Write-Host "未输入微信小程序ID，退出..." -ForegroundColor Red
    #         Read-Host "按回车键退出"
    #         exit 1
    #     }
    # } else {
        $WxId = $AutoWxId
    # }
} else {
    Write-Host "❌ 无法从路径自动提取微信小程序ID" -ForegroundColor Yellow
    $WxId = Read-Host "请手动输入微信小程序ID"
    if ([string]::IsNullOrEmpty($WxId)) {
        Write-Host "未输入微信小程序ID，退出..." -ForegroundColor Red
        Read-Host "按回车键退出"
        exit 1
    }
}

Write-Host ""
Write-Host "开始处理..." -ForegroundColor Yellow
Write-Host "文件: $WxapkgPath"
Write-Host "微信ID: $WxId"
Write-Host "----------------------------------------"

# 获取脚本目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 工具路径
$DecryptTool = Join-Path $ScriptDir "1.first\pc_wxapkg_decrypt.exe"
$UnpackTool = Join-Path $ScriptDir "2.second\nodejs\wuWxapkg.js"
$NodeExe = Join-Path $ScriptDir "2.second\nodejs\node.exe"

# 检查工具是否存在
if (-not (Test-Path $DecryptTool)) {
    Write-Host "错误: 解密工具不存在: $DecryptTool" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

if (-not (Test-Path $UnpackTool)) {
    Write-Host "错误: 解包工具不存在: $UnpackTool" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

if (-not (Test-Path $NodeExe)) {
    Write-Host "错误: Node.js不存在: $NodeExe" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

# 创建输出目录
$OutputDir = Join-Path $ScriptDir "output\$WxId"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$DecryptedFile = Join-Path $OutputDir "decrypted.wxapkg"

Write-Host ""
Write-Host "步骤1: 解密wxapkg文件..." -ForegroundColor Yellow

# 执行解密
$DecryptArgs = @("-wxid", $WxId, "-in", "`"$WxapkgPath`"", "-out", "`"$DecryptedFile`"")
try {
    $DecryptProcess = Start-Process -FilePath $DecryptTool -ArgumentList $DecryptArgs -WorkingDirectory (Split-Path $DecryptTool) -Wait -PassThru -NoNewWindow
    
    if ($DecryptProcess.ExitCode -eq 0) {
        Write-Host "✅ 解密成功!" -ForegroundColor Green
    } else {
        Write-Host "❌ 解密失败!" -ForegroundColor Red
        Read-Host "按回车键退出"
        exit 1
    }
} catch {
    Write-Host "❌ 解密过程出错: $_" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

Write-Host ""
Write-Host "步骤2: 解包wxapkg文件..." -ForegroundColor Yellow
Write-Host "解包输入文件: $DecryptedFile" -ForegroundColor Cyan
Write-Host "Node.js路径: $NodeExe" -ForegroundColor Cyan
Write-Host "解包工具路径: $UnpackTool" -ForegroundColor Cyan
Write-Host "工作目录: $(Split-Path $UnpackTool)" -ForegroundColor Cyan

# 检查Node.js版本
Write-Host "检查Node.js版本..." -ForegroundColor Yellow
try {
    $NodeVersion = & $NodeExe --version
    Write-Host "Node.js版本: $NodeVersion" -ForegroundColor Green
} catch {
    Write-Host "无法获取Node.js版本: $_" -ForegroundColor Red
}

# 执行解包
$UnpackArgs = @("`"$UnpackTool`"", "`"$DecryptedFile`"")
Write-Host "执行命令: $NodeExe $($UnpackArgs -join ' ')" -ForegroundColor Cyan

# 保存当前目录
$OriginalLocation = Get-Location

try {
    # 切换到nodejs目录，模拟人工操作
    $NodejsDir = Split-Path $UnpackTool
    Write-Host "切换到目录: $NodejsDir" -ForegroundColor Cyan
    Set-Location $NodejsDir
    
    # 构建相对路径的解包命令
    $RelativeUnpackTool = ".\wuWxapkg.js"
    $UnpackCommand = "node `"$RelativeUnpackTool`" `"$DecryptedFile`""
    Write-Host "执行命令: $UnpackCommand" -ForegroundColor Cyan
    
    # 使用Invoke-Expression执行命令，模拟在命令行中直接输入
    $UnpackResult = Invoke-Expression $UnpackCommand 2>&1
    $UnpackExitCode = $LASTEXITCODE
    
    Write-Host "命令执行完成，退出码: $UnpackExitCode" -ForegroundColor Cyan
    
    # 解包工具会在输入文件的同级目录下创建以文件名命名的文件夹
    $DecryptedFileName = [System.IO.Path]::GetFileNameWithoutExtension($DecryptedFile)
    $SourceDir = Join-Path (Split-Path $DecryptedFile) $DecryptedFileName
    $UnpackDir = Join-Path $OutputDir "unpacked"
    
    Write-Host "查找解包结果目录: $SourceDir" -ForegroundColor Cyan
    
    # 检查是否有文件被解包出来，即使退出码不为0
    if (Test-Path $SourceDir) {
        # 移动解包后的文件到指定目录
        if (Test-Path $UnpackDir) {
            Remove-Item $UnpackDir -Recurse -Force
        }
        Move-Item $SourceDir $UnpackDir
        
        Write-Host "✅ 解包成功!" -ForegroundColor Green
        Write-Host "文件已保存到: $UnpackDir" -ForegroundColor Green
        
        if ($UnpackExitCode -ne 0) {
            Write-Host "⚠️  注意: 解包过程中有警告，但文件已成功提取" -ForegroundColor Yellow
        }
        
        # 提取和分类native资源文件
        Extract-NativeResources -UnpackDir $UnpackDir -OutputDir $OutputDir
    } else {
        Write-Host "❌ 解包失败! 未找到解包后的文件夹: $SourceDir" -ForegroundColor Red
        if ($UnpackExitCode -ne 0) {
            Write-Host "解包工具退出码: $UnpackExitCode" -ForegroundColor Red
        }
        
        # 显示命令输出
        if ($UnpackResult) {
            Write-Host "命令输出:" -ForegroundColor Yellow
            $UnpackResult | Write-Host -ForegroundColor Yellow
        }
        
        # 恢复原目录
        Set-Location $OriginalLocation
        Read-Host "按回车键退出"
        exit 1
    }
} catch {
    Write-Host "❌ 解包过程出错: $_" -ForegroundColor Red
    
    # 即使出错也检查是否有文件被解包出来
    $DecryptedFileName = [System.IO.Path]::GetFileNameWithoutExtension($DecryptedFile)
    $SourceDir = Join-Path (Split-Path $DecryptedFile) $DecryptedFileName
    $UnpackDir = Join-Path $OutputDir "unpacked"
    
    if (Test-Path $SourceDir) {
        if (Test-Path $UnpackDir) {
            Remove-Item $UnpackDir -Recurse -Force
        }
        Move-Item $SourceDir $UnpackDir
        Write-Host "⚠️  虽然有错误，但文件已成功提取到: $UnpackDir" -ForegroundColor Yellow
        
        # 提取和分类native资源文件
        Extract-NativeResources -UnpackDir $UnpackDir -OutputDir $OutputDir
    } else {
        # 恢复原目录
        Set-Location $OriginalLocation
        Read-Host "按回车键退出"
        exit 1
    }
} finally {
    # 恢复原目录
    Set-Location $OriginalLocation
}

# 清理临时文件
if (Test-Path $DecryptedFile) {
    Remove-Item $DecryptedFile -Force
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 处理完成!" -ForegroundColor Green
Write-Host "结果保存在: $OutputDir\unpacked" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$OpenFolder = Read-Host "是否打开输出文件夹? (y/n)"
if ($OpenFolder -eq "y") {
    $FinalOutputDir = Join-Path $OutputDir "unpacked"
    if (Test-Path $FinalOutputDir) {
        Invoke-Item $FinalOutputDir
    }
}

Write-Host ""
Read-Host "按回车键退出" 