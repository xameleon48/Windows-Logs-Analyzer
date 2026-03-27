$installContent = @'
<#
.SYNOPSIS
    Установщик Windows Logs Analyzer
.DESCRIPTION
    Скрипт для установки Analyze-Logs.ps1 в систему
.EXAMPLE
    .\install.ps1
#>

Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║     Windows Logs Analyzer - Установка                           ║
║     Анализ Windows логов с расширенными возможностями           ║
╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Проверка версии PowerShell
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 5) {
    Write-Host "❌ Ошибка: Требуется PowerShell 5.1 или выше" -ForegroundColor Red
    Write-Host "   Текущая версия: $psVersion" -ForegroundColor Red
    exit 1
}
Write-Host "✅ PowerShell версия: $psVersion" -ForegroundColor Green

# Создание папки для скриптов
$scriptPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Scripts"
if (-not (Test-Path $scriptPath)) {
    New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
    Write-Host "✅ Создана папка: $scriptPath" -ForegroundColor Green
} else {
    Write-Host "✅ Папка существует: $scriptPath" -ForegroundColor Green
}

# Копирование скрипта
$sourceScript = Join-Path $PSScriptRoot "Analyze-Logs.ps1"
$destScript = Join-Path $scriptPath "Analyze-Logs.ps1"

if (Test-Path $sourceScript) {
    Copy-Item $sourceScript $destScript -Force
    Write-Host "✅ Скрипт скопирован: $destScript" -ForegroundColor Green
} else {
    Write-Host "❌ Ошибка: Файл Analyze-Logs.ps1 не найден!" -ForegroundColor Red
    Write-Host "   Убедитесь, что install.ps1 находится в той же папке, что и Analyze-Logs.ps1" -ForegroundColor Yellow
    exit 1
}

# Добавление алиаса в профиль
$profilePath = $PROFILE.CurrentUserAllHosts
$aliasCommand = "`n# Windows Logs Analyzer`nSet-Alias -Name analyze-logs -Value '$destScript' -Scope Global -ErrorAction SilentlyContinue`n"

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
    Write-Host "✅ Создан профиль PowerShell: $profilePath" -ForegroundColor Green
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notlike "*Windows Logs Analyzer*") {
    Add-Content -Path $profilePath -Value $aliasCommand -Force
    Write-Host "✅ Алиас 'analyze-logs' добавлен в профиль" -ForegroundColor Green
} else {
    Write-Host "✅ Алиас 'analyze-logs' уже существует" -ForegroundColor Green
}

# Проверка политики выполнения
$executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($executionPolicy -eq 'Restricted') {
    Write-Host "⚠️  Внимание: Политика выполнения скриптов установлена как Restricted" -ForegroundColor Yellow
    Write-Host "   Рекомендуется изменить на RemoteSigned:" -ForegroundColor Yellow
    Write-Host "   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Cyan
}

Write-Host @"

╔══════════════════════════════════════════════════════════════════╗
║                    ✅ УСТАНОВКА ЗАВЕРШЕНА!                       ║
╚══════════════════════════════════════════════════════════════════╝

📌 Теперь вы можете использовать команду:

    analyze-logs -LogPath "C:\Logs"

📌 Или полный путь к скрипту:

    $destScript

📌 Примеры использования:

    # Поиск в одном файле
    analyze-logs -LogPath "C:\Logs\Security.evtx" -SearchText "192.168.1.100"

    # Поиск в папке с экспортом
    analyze-logs -LogPath "C:\Logs" -SearchText "error" -ExportCSV

    # Поиск за последние 24 часа
    analyze-logs -LogPath "C:\Logs" -SearchText "powershell.exe" -LastHours 24

    # Справка
    analyze-logs -Help

📌 Для применения алиаса перезапустите PowerShell или выполните:

    . $profilePath

⭐ Если проект помог вам, поставьте звезду на GitHub:
   https://github.com/xameleon48/Windows-Logs-Analyzer

"@ -ForegroundColor Green

# Перезагрузка профиля
try {
    . $profilePath
    Write-Host "✅ Профиль перезагружен" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Для применения алиаса перезапустите PowerShell" -ForegroundColor Yellow
}
'@

$installContent | Out-File -FilePath "install.ps1" -Encoding UTF8
Write-Host "✅ install.ps1 создан" -ForegroundColor Green