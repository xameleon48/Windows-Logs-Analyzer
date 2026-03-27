<#
.SYNOPSIS
    Анализ Windows логов с поддержкой кириллицы и очисткой пустых файлов
.DESCRIPTION
    Скрипт для анализа .evtx файлов с возможностью фильтрации
#>

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$LogPath,
    
    [string]$ExportPath,
    
    [string]$SearchText,
    
    [string]$SearchIP,
    
    [string]$SearchProcess,
    
    [string]$EventID,
    
    [datetime]$StartTime,
    
    [datetime]$EndTime,
    
    [int]$LastHours,
    
    [int]$LastDays,
    
    [switch]$Today,
    
    [switch]$Yesterday,
    
    [switch]$ThisHour,
    
    [ValidateSet("Error", "Warning", "Information", "Critical", "Verbose")]
    [string]$Level,
    
    [string]$LogName,
    
    [switch]$ExportCSV,
    
    [switch]$ShowSummary,
    
    [int]$MaxEvents = 100000,
    
    [switch]$Help,
    
    [switch]$CleanEmptyLogs,
    [switch]$DryRun,
    [int]$MinFileSizeKB = 10,
    
    [switch]$UseParallel,
    [int]$MaxThreads = 4,
    [int]$TimeoutSeconds = 30
)

# Функция для раскрашенного вывода
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    $validColors = [System.ConsoleColor].GetEnumNames()
    if ($ForegroundColor -in $validColors) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Message
    }
}

# Функция для вывода разделителя
function Write-Separator {
    param([string]$Color = "Cyan")
    $separator = "=" * 80
    Write-ColorOutput $separator $Color
}

# Функция для вывода справки
function Show-Help {
    Write-Separator -Color "Cyan"
    Write-ColorOutput "📚 СПРАВКА ПО СКРИПТУ ANALYZE-LOGS.PS1" "Yellow"
    Write-Separator -Color "Cyan"
    
    Write-ColorOutput "`n📌 НАЗНАЧЕНИЕ:" "Green"
    Write-ColorOutput "  Анализ Windows логов (.evtx) с поиском по тексту, IP, процессам, времени" "White"
    
    Write-ColorOutput "`n📌 ИСПОЛЬЗОВАНИЕ:" "Green"
    Write-ColorOutput "  .\Analyze-Logs.ps1 -LogPath <путь> [параметры]" "Cyan"
    
    Write-ColorOutput "`n📌 ОСНОВНЫЕ ПАРАМЕТРЫ:" "Green"
    Write-ColorOutput "  -LogPath <путь>          # Путь к файлу .evtx или папке с логами" "White"
    
    Write-ColorOutput "`n📌 ПОИСК ПО СОДЕРЖИМОМУ:" "Green"
    Write-ColorOutput "  -SearchText <текст>      # Поиск по тексту в сообщении" "White"
    Write-ColorOutput "  -SearchIP <IP>           # Поиск по IP-адресу" "White"
    Write-ColorOutput "  -SearchProcess <процесс> # Поиск по имени процесса" "White"
    Write-ColorOutput "  -EventID <ID>            # Поиск по EventID (можно несколько: 4624,4625)" "White"
    Write-ColorOutput "  -Level <уровень>         # Уровень: Error, Warning, Information, Critical" "White"
    
    Write-ColorOutput "`n📌 ВРЕМЕННЫЕ ФИЛЬТРЫ:" "Green"
    Write-ColorOutput "  -StartTime <дата/время>  # Начало периода" "White"
    Write-ColorOutput "  -EndTime <дата/время>    # Конец периода" "White"
    Write-ColorOutput "  -LastHours <часы>        # За последние N часов" "White"
    Write-ColorOutput "  -LastDays <дни>          # За последние N дней" "White"
    Write-ColorOutput "  -Today                   # Только за сегодня" "White"
    Write-ColorOutput "  -Yesterday               # Только за вчера" "White"
    
    Write-ColorOutput "`n📌 ПРОИЗВОДИТЕЛЬНОСТЬ:" "Green"
    Write-ColorOutput "  -UseParallel             # Включить параллельную обработку" "White"
    Write-ColorOutput "  -MaxThreads <число>      # Количество потоков (по умолч. 4)" "White"
    Write-ColorOutput "  -TimeoutSeconds <сек>    # Таймаут на файл (по умолч. 30)" "White"
    
    Write-ColorOutput "`n📌 УПРАВЛЕНИЕ ВЫВОДОМ:" "Green"
    Write-ColorOutput "  -ExportCSV               # Экспорт результатов в CSV и HTML" "White"
    Write-ColorOutput "  -ShowSummary             # Показать только сводку" "White"
    
    Write-ColorOutput "`n📌 ОЧИСТКА ПУСТЫХ ФАЙЛОВ:" "Green"
    Write-ColorOutput "  -CleanEmptyLogs          # Очистить пустые файлы логов" "White"
    Write-ColorOutput "  -DryRun                  # Показать что будет удалено без реального удаления" "White"
    Write-ColorOutput "  -MinFileSizeKB <KB>      # Минимальный размер файла (по умолч. 10 KB)" "White"
    
    Write-ColorOutput "`n📌 ПРИМЕРЫ:" "Yellow"
    Write-ColorOutput "  # Поиск в одном файле" "Gray"
    Write-ColorOutput "  .\Analyze-Logs.ps1 -LogPath 'C:\Logs\file.evtx' -SearchText 'OU=Transit' -ExportCSV" "Cyan"
    Write-ColorOutput "" "White"
    Write-ColorOutput "  # Поиск в папке за последние 30 дней" "Gray"
    Write-ColorOutput "  .\Analyze-Logs.ps1 -LogPath 'C:\Logs' -SearchText 'error' -LastDays 30 -UseParallel -MaxThreads 6" "Cyan"
    Write-ColorOutput "" "White"
    Write-ColorOutput "  # Очистка пустых файлов" "Gray"
    Write-ColorOutput "  .\Analyze-Logs.ps1 -LogPath 'C:\Logs' -CleanEmptyLogs -DryRun" "Cyan"
    Write-ColorOutput "" "White"
    Write-ColorOutput "  # Справка" "Gray"
    Write-ColorOutput "  .\Analyze-Logs.ps1 -Help" "Cyan"
    
    Write-Separator -Color "Cyan"
}

# Функция для очистки пустых файлов
function Clean-EmptyLogFiles {
    param(
        [string]$Path,
        [int]$MinSizeKB,
        [switch]$DryRun
    )
    
    Write-ColorOutput "`n" "White"
    Write-Separator -Color "Cyan"
    Write-ColorOutput "🧹 ОЧИСТКА ПУСТЫХ ФАЙЛОВ ЛОГОВ" "Yellow"
    Write-Separator -Color "Cyan"
    Write-ColorOutput "Путь: $Path" "White"
    Write-ColorOutput "Минимальный размер: $MinSizeKB KB" "White"
    
    if ($DryRun) {
        Write-ColorOutput "Режим: ТОЛЬКО ПРОСМОТР (без удаления)" "Yellow"
    } else {
        Write-ColorOutput "Режим: УДАЛЕНИЕ" "Red"
        Write-ColorOutput "⚠️  ВНИМАНИЕ: Файлы будут удалены без возможности восстановления!" "Red"
        Write-ColorOutput "Для продолжения нажмите Enter, для отмены Ctrl+C..." "Yellow"
        Read-Host
    }
    
    Write-ColorOutput "`n🔍 Сканирование файлов..." "Cyan"
    
    $allFiles = Get-ChildItem -Path $Path -Filter "*.evtx" -Recurse -ErrorAction SilentlyContinue
    Write-ColorOutput "Всего найдено файлов: $($allFiles.Count)" "Green"
    
    $emptyFiles = @()
    $totalSizeSaved = 0
    
    foreach ($file in $allFiles) {
        $sizeKB = [math]::Round($file.Length / 1024, 2)
        
        $isEmpty = $false
        $reason = ""
        
        if ($file.Length -eq 0) {
            $isEmpty = $true
            $reason = "Файл полностью пуст (0 байт)"
        }
        elseif ($sizeKB -lt $MinSizeKB) {
            $isEmpty = $true
            $reason = "Файл слишком маленький ($sizeKB KB < $MinSizeKB KB)"
        }
        else {
            try {
                $eventCount = (Get-WinEvent -Path $file.FullName -MaxEvents 1 -ErrorAction SilentlyContinue).Count
                if ($eventCount -eq 0) {
                    $isEmpty = $true
                    $reason = "Нет событий (0 событий)"
                }
            }
            catch {
                $isEmpty = $true
                $reason = "Не удается прочитать файл (возможно поврежден)"
            }
        }
        
        if ($isEmpty) {
            $emptyFiles += [PSCustomObject]@{
                FullName = $file.FullName
                Name = $file.Name
                SizeKB = $sizeKB
                Reason = $reason
                Directory = $file.DirectoryName
            }
            $totalSizeSaved += $sizeKB
        }
    }
    
    if ($emptyFiles.Count -eq 0) {
        Write-ColorOutput "`n✅ Пустые файлы не найдены!" "Green"
        return
    }
    
    Write-ColorOutput "`n📋 Найдено пустых файлов: $($emptyFiles.Count)" "Yellow"
    Write-ColorOutput "💾 Освободится места: $([math]::Round($totalSizeSaved, 2)) KB ($([math]::Round($totalSizeSaved/1024, 2)) MB)" "Yellow"
    
    Write-ColorOutput "`n📄 Список файлов для удаления:" "Cyan"
    foreach ($file in $emptyFiles) {
        Write-ColorOutput "  • $($file.Name)" "Gray"
        Write-ColorOutput "    Размер: $($file.SizeKB) KB | Причина: $($file.Reason)" "DarkGray"
    }
    
    if (-not $DryRun) {
        Write-ColorOutput "`n⚠️  Вы уверены, что хотите удалить эти файлы? (Y/N)" "Red"
        $confirmation = Read-Host
        if ($confirmation -ne 'Y' -and $confirmation -ne 'y') {
            Write-ColorOutput "❌ Операция отменена." "Yellow"
            return
        }
        
        Write-ColorOutput "`n🗑️ Удаление файлов..." "Cyan"
        $deletedCount = 0
        
        foreach ($file in $emptyFiles) {
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                Write-ColorOutput "  ✓ Удален: $($file.Name)" "Green"
                $deletedCount++
            }
            catch {
                Write-ColorOutput "  ✗ Ошибка: $($_.Exception.Message)" "Red"
            }
        }
        
        Write-ColorOutput "`n✅ Удалено: $deletedCount файлов" "Green"
        Write-ColorOutput "💾 Освобождено: $([math]::Round($totalSizeSaved, 2)) KB" "Green"
    }
}

# Функция для экспорта в CSV
function Export-ToCSV {
    param([array]$Data, [string]$FilePath)
    try {
        $Data | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
        Write-ColorOutput "  ✓ CSV: $FilePath" "Green"
        return $true
    }
    catch {
        $csvContent = $Data | ConvertTo-Csv -Delimiter ";" -NoTypeInformation
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllLines($FilePath, $csvContent, $utf8WithBom)
        Write-ColorOutput "  ✓ CSV: $FilePath" "Green"
        return $true
    }
}

# Функция для экспорта в HTML (с добавленным именем журнала)
function Export-ToHTML {
    param([array]$Data, [string]$FilePath, [string]$SearchText)
    try {
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Анализ логов Windows</title>
<style>
body{font-family:'Segoe UI',Arial;margin:20px;background:#f5f5f5}
h1{color:#333;border-bottom:3px solid #4CAF50;padding-bottom:10px}
.summary{background:#fff;padding:15px;border-radius:5px;margin-bottom:20px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
table{border-collapse:collapse;width:100%;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
th,td{border:1px solid #ddd;padding:12px;text-align:left;vertical-align:top}
th{background:#4CAF50;color:white;position:sticky;top:0}
tr:nth-child(even){background:#f9f9f9}
tr:hover{background:#f5f5f5}
.error{color:#d32f2f;font-weight:bold}
.warning{color:#f57c00;font-weight:bold}
.critical{color:#c62828;font-weight:bold}
pre{white-space:pre-wrap;font-family:'Consolas',monospace;font-size:12px;margin:0;background:#f8f8f8;padding:8px;border-radius:3px}
.highlight{background:yellow;font-weight:bold}
.stats{display:inline-block;margin:10px;padding:10px;background:#e3f2fd;border-radius:5px}
.stats-number{font-size:24px;font-weight:bold;color:#1976d2}
.logname{font-family:monospace;font-size:11px;color:#666}
</style>
</head>
<body>
<h1>📊 Анализ логов Windows</h1>
<div class="summary">
<h2>📈 Общая статистика</h2>
<div class="stats"><div class="stats-number">$($Data.Count)</div><div>Всего событий</div></div>
<div class="stats"><div class="stats-number">$($Data | Group-Object EventID | Measure-Object | Select-Object -ExpandProperty Count)</div><div>Уникальных EventID</div></div>
<div class="stats"><div class="stats-number">$($Data | Group-Object LogFileName | Measure-Object | Select-Object -ExpandProperty Count)</div><div>Файлов логов</div></div>
</div>
<h2>📋 Детальный список событий</h2>
<div style="overflow-x:auto">
<table>
<thead>
<tr>
<th>#</th>
<th>Время</th>
<th>Журнал</th>
<th>EventID</th>
<th>Уровень</th>
<th>Сообщение</th>
</tr>
</thead>
<tbody>
"@
        $i = 1
        foreach ($e in $Data) {
            $msg = $e.Message
            if ($SearchText) { 
                $msg = $msg -replace "($([regex]::Escape($SearchText)))", '<span class="highlight">$1</span>'
            }
            $levelClass = switch ($e.Level) {
                "Error" { "error" }
                "Warning" { "warning" }
                "Critical" { "critical" }
                default { "" }
            }
            # Укорачиваем имя журнала для читаемости
            $shortLogName = $e.LogFileName
            if ($shortLogName.Length -gt 60) {
                $shortLogName = $shortLogName.Substring(0, 57) + "..."
            }
            $htmlContent += @"
<tr>
<td style='text-align:center'>$i</td>
<td style='white-space:nowrap'>$($e.TimeCreated)</td>
<td><span class='logname' title='$($e.LogFileName)'>$shortLogName</span></td>
<td style='text-align:center'>$($e.EventID)</td>
<td class='$levelClass'>$($e.Level)</td>
<td><pre>$msg</pre></td>
</tr>
"@
            $i++
        }
        $htmlContent += @"
</tbody>
</table>
</div>
<div style='margin-top:20px;padding:10px;background:#e8f5e9;border-radius:5px;text-align:center;font-size:12px;color:#666'>
Сгенерировано: $(Get-Date) | Всего событий: $($Data.Count) | Файлов: $($Data | Group-Object LogFileName | Measure-Object | Select-Object -ExpandProperty Count)
</div>
</body>
</html>
"@
        
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($FilePath, $htmlContent, $utf8WithBom)
        Write-ColorOutput "  ✓ HTML: $FilePath" "Green"
        return $true
    }
    catch { 
        Write-ColorOutput "  ✗ Ошибка HTML: $($_.Exception.Message)" "Red"
        return $false 
    }
}

# ============================================
# ОСНОВНАЯ ЛОГИКА
# ============================================

# Если запрошена справка или нет параметров
if ($Help -or ($PSBoundParameters.Count -eq 0 -and -not $CleanEmptyLogs)) {
    Show-Help
    exit 0
}

# Если очистка файлов
if ($CleanEmptyLogs) {
    if ([string]::IsNullOrEmpty($LogPath)) {
        Write-ColorOutput "❌ Ошибка: Для очистки укажите -LogPath" "Red"
        exit 1
    }
    if (-not (Test-Path $LogPath)) {
        Write-ColorOutput "❌ Ошибка: Путь $LogPath не существует!" "Red"
        exit 1
    }
    Clean-EmptyLogFiles -Path $LogPath -MinSizeKB $MinFileSizeKB -DryRun:$DryRun
    exit 0
}

# Если нет LogPath для поиска
if ([string]::IsNullOrEmpty($LogPath)) {
    Write-ColorOutput "❌ Ошибка: Не указан параметр -LogPath" "Red"
    Write-ColorOutput "Используйте -Help для справки" "Yellow"
    exit 1
}

# Проверка существования пути
if (-not (Test-Path $LogPath)) {
    Write-ColorOutput "❌ Ошибка: Путь $LogPath не существует!" "Red"
    exit 1
}

# Основной анализ
try {
    $startTimeScript = Get-Date
    
    Write-Separator -Color "Cyan"
    Write-ColorOutput "📊 АНАЛИЗ WINDOWS ЛОГОВ" "Yellow"
    Write-Separator -Color "Cyan"
    
    $isFile = Test-Path -Path $LogPath -PathType Leaf
    Write-ColorOutput "📁 Путь: $LogPath" "White"
    if ($isFile) { Write-ColorOutput "📄 Тип: Файл" "Green" } 
    else { Write-ColorOutput "📂 Тип: Папка" "Green" }
    
    # Обработка временных параметров (ИСПРАВЛЕНО)
    $actualStartTime = $null
    $actualEndTime = $null
    
    if ($Today) {
        $actualStartTime = (Get-Date).Date
        $actualEndTime = $actualStartTime.AddDays(1).AddSeconds(-1)
        Write-ColorOutput "⏰ Режим: Сегодня" "Gray"
    }
    elseif ($Yesterday) {
        $actualStartTime = (Get-Date).AddDays(-1).Date
        $actualEndTime = $actualStartTime.AddDays(1).AddSeconds(-1)
        Write-ColorOutput "⏰ Режим: Вчера" "Gray"
    }
    elseif ($ThisHour) {
        $actualStartTime = (Get-Date).Date.AddHours((Get-Date).Hour)
        $actualEndTime = $actualStartTime.AddHours(1).AddSeconds(-1)
        Write-ColorOutput "⏰ Режим: Текущий час" "Gray"
    }
    elseif ($LastHours) {
        $actualStartTime = (Get-Date).AddHours(-$LastHours)
        $actualEndTime = (Get-Date)
        Write-ColorOutput "⏰ Режим: Последние $LastHours часов" "Gray"
    }
    elseif ($LastDays) {
        $actualStartTime = (Get-Date).AddDays(-$LastDays)
        $actualEndTime = (Get-Date)
        Write-ColorOutput "⏰ Режим: Последние $LastDays дней" "Gray"
        Write-ColorOutput "  • Начало (локальное): $actualStartTime" "DarkGray"
        Write-ColorOutput "  • Конец (локальное): $actualEndTime" "DarkGray"
    }
    elseif ($StartTime -or $EndTime) {
        $actualStartTime = $StartTime
        $actualEndTime = $EndTime
        if ($actualStartTime) { Write-ColorOutput "⏰ Начало: $actualStartTime" "Gray" }
        if ($actualEndTime) { Write-ColorOutput "⏰ Конец: $actualEndTime" "Gray" }
    }
    
    # Вывод фильтров
    Write-ColorOutput "`n🔍 Примененные фильтры:" "Green"
    if ($EventID) { Write-ColorOutput "  • EventID: $EventID" "Gray" }
    if ($Level) { Write-ColorOutput "  • Уровень: $Level" "Gray" }
    if ($LogName) { Write-ColorOutput "  • Журналы: $LogName" "Gray" }
    if ($SearchText) { Write-ColorOutput "  • Текст: $SearchText" "Gray" }
    if ($SearchIP) { Write-ColorOutput "  • IP: $SearchIP" "Gray" }
    if ($SearchProcess) { Write-ColorOutput "  • Процесс: $SearchProcess" "Gray" }
    if ($UseParallel) { Write-ColorOutput "  • Параллельная обработка: Да (потоков: $MaxThreads)" "Gray" }
    Write-ColorOutput "  • Таймаут на файл: ${TimeoutSeconds} сек" "Gray"
    
    # Получение файлов
    Write-ColorOutput "`n🔎 Сканирование файлов..." "Cyan"
    
    $evtxFiles = @()
    if ($isFile) {
        if ($LogPath -like "*.evtx") {
            $evtxFiles += Get-Item $LogPath
            Write-ColorOutput "  ✓ Найден файл: $(Split-Path $LogPath -Leaf)" "Green"
        } else {
            Write-ColorOutput "❌ Ошибка: Указанный файл не является .evtx!" "Red"
            exit 1
        }
    } else {
        $evtxFiles = Get-ChildItem -Path $LogPath -Filter "*.evtx" -Recurse -ErrorAction SilentlyContinue
        Write-ColorOutput "  ✓ Найдено файлов: $($evtxFiles.Count)" "Green"
    }
    
    if ($evtxFiles.Count -eq 0) {
        Write-ColorOutput "❌ Ошибка: Не найдено .evtx файлов!" "Red"
        exit 1
    }
    
    # Парсинг EventID
    $eventIDs = $null
    if ($EventID) { $eventIDs = $EventID -split ',' | ForEach-Object { [int]$_ } }
    
    # Парсинг LogName
    $logNames = $null
    if ($LogName) { $logNames = $LogName -split ',' }
    
    # Обработка файлов
    $allEvents = @()
    $skippedEmpty = 0
    $processedFiles = 0
    $errorFiles = 0
    
    Write-ColorOutput "`n🔄 Обработка файлов..." "Cyan"
    
    # Последовательная обработка (более надежная для отладки)
    foreach ($file in $evtxFiles) {
        $processedFiles++
        
        $percent = [math]::Round(($processedFiles / $evtxFiles.Count) * 100, 2)
        Write-Progress -Activity "Обработка файлов" -Status "$($file.Name)" -PercentComplete $percent -CurrentOperation "$processedFiles из $($evtxFiles.Count)"
        
        if ($file.Length -lt 1024) {
            Write-ColorOutput "  ⏭ [$processedFiles/$($evtxFiles.Count)] $($file.Name) - пустой ($([math]::Round($file.Length/1024,2)) KB)" "Yellow"
            $skippedEmpty++
            continue
        }
        
        Write-ColorOutput "  📄 [$processedFiles/$($evtxFiles.Count)] $($file.Name) ($([math]::Round($file.Length/1024,0)) KB)" "Gray"
        
        try {
            # Строим XPath фильтр (с правильным UTC)
            $xPathParts = @()
            
            if ($eventIDs -and $eventIDs.Count -gt 0) { 
                $xPathParts += "EventID=" + ($eventIDs -join " or EventID=") 
            }
            
            if ($Level) {
                $levelMap = @{"Error"="2";"Warning"="3";"Information"="4";"Critical"="1";"Verbose"="5"}
                if ($levelMap.ContainsKey($Level)) {
                    $xPathParts += "Level=$($levelMap[$Level])"
                }
            }
            
            # КРИТИЧЕСКИ ВАЖНО: Правильное преобразование времени в UTC
            if ($actualStartTime) {
                $startTimeUTC = $actualStartTime.ToUniversalTime()
                $startTimeStr = $startTimeUTC.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                $xPathParts += "@SystemTime>='$startTimeStr'"
                if ($processedFiles -eq 1) {
                    Write-ColorOutput "    • Время начала (UTC): $startTimeStr" "DarkGray"
                }
            }
            
            if ($actualEndTime) {
                $endTimeUTC = $actualEndTime.ToUniversalTime()
                $endTimeStr = $endTimeUTC.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                $xPathParts += "@SystemTime<='$endTimeStr'"
                if ($processedFiles -eq 1) {
                    Write-ColorOutput "    • Время конца (UTC): $endTimeStr" "DarkGray"
                }
            }
            
            # Получаем события
            $events = $null
            if ($xPathParts.Count -gt 0) {
                $xPathFilter = "*[System[" + ($xPathParts -join " and ") + "]]"
                $events = Get-WinEvent -Path $file.FullName -FilterXPath $xPathFilter -ErrorAction SilentlyContinue
            } else {
                $events = Get-WinEvent -Path $file.FullName -ErrorAction SilentlyContinue
            }
            
            if (-not $events) { 
                Write-ColorOutput "    ⚡ Нет событий по фильтрам" "DarkGray"
                continue 
            }
            
            Write-ColorOutput "    ✓ Найдено событий: $($events.Count)" "Green"
            
            $fileEventCount = 0
            foreach ($event in $events) {
                if ($allEvents.Count -ge $MaxEvents) { 
                    Write-ColorOutput "`n⚠ Достигнут лимит $MaxEvents событий" "Yellow"
                    break 
                }
                
                $message = if ($event.Message) { $event.Message } else { "" }
                $match = $true
                
                if ($SearchText -and $message.IndexOf($SearchText, [StringComparison]::OrdinalIgnoreCase) -eq -1) { $match = $false }
                if ($match -and $SearchIP -and $message -notmatch "\b$([regex]::Escape($SearchIP))\b") { $match = $false }
                if ($match -and $SearchProcess -and $message -notmatch "\\$SearchProcess|$SearchProcess\.exe") { $match = $false }
                if ($match -and $logNames -and $logNames.Count -gt 0) {
                    $logMatch = $false
                    foreach ($ln in $logNames) {
                        if ($file.Name -like "*$ln*") { $logMatch = $true; break }
                    }
                    if (-not $logMatch) { $match = $false }
                }
                
                if ($match) {
                    $allEvents += [PSCustomObject]@{
                        LogFileName = $file.Name
                        EventID = $event.Id
                        TimeCreated = $event.TimeCreated
                        Level = $event.LevelDisplayName
                        Provider = $event.ProviderName
                        Message = if ($message.Length -gt 1000) { $message.Substring(0, 1000) + "..." } else { $message }
                    }
                    $fileEventCount++
                }
            }
            
            if ($fileEventCount -gt 0) {
                Write-ColorOutput "    🎯 Найдено по фильтрам: $fileEventCount" "Cyan"
            }
        }
        catch {
            Write-ColorOutput "    ❌ Ошибка: $($_.Exception.Message)" "Red"
            $errorFiles++
        }
        
        if ($allEvents.Count -ge $MaxEvents) { break }
    }
    
    Write-Progress -Activity "Обработка файлов" -Completed
    
    $elapsedTime = ((Get-Date) - $startTimeScript).TotalSeconds
    
    Write-ColorOutput "`n" "White"
    Write-Separator -Color "Cyan"
    Write-ColorOutput "📊 РЕЗУЛЬТАТЫ АНАЛИЗА" "Yellow"
    Write-Separator -Color "Cyan"
    Write-ColorOutput "✅ Обработано файлов: $processedFiles из $($evtxFiles.Count)" "White"
    if ($skippedEmpty -gt 0) { Write-ColorOutput "⏭ Пропущено пустых: $skippedEmpty" "Yellow" }
    if ($errorFiles -gt 0) { Write-ColorOutput "❌ Ошибок: $errorFiles" "Red" }
    Write-ColorOutput "🔍 Найдено событий: $($allEvents.Count)" "Green"
    Write-ColorOutput "⏱ Время выполнения: $([math]::Round($elapsedTime, 2)) секунд" "White"
    
    if ($allEvents.Count -eq 0) {
        Write-ColorOutput "`n⚠ События по заданным фильтрам не найдены." "Yellow"
        Write-ColorOutput "💡 Советы:" "Gray"
        Write-ColorOutput "  • Проверьте правильность текста поиска" "Gray"
        Write-ColorOutput "  • Попробуйте без временных фильтров: уберите -StartTime/-EndTime/-LastDays" "Gray"
        Write-ColorOutput "  • Или расширьте временной диапазон" "Gray"
        Write-ColorOutput "  • Запустите с -LastDays 30 (если не работает, проверьте системное время)" "Gray"
        exit 0
    }
    
    # Вывод первых событий
    if (-not $ShowSummary) {
        Write-ColorOutput "`n📋 НАЙДЕННЫЕ СОБЫТИЯ (первые 10):" "Yellow"
        $i = 1
        foreach ($e in $allEvents | Select-Object -First 10) {
            $color = switch ($e.Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Critical" { "DarkRed" }
                default { "White" }
            }
            Write-ColorOutput "`n[$i] $($e.TimeCreated) | EventID: $($e.EventID) | $($e.Level)" $color
            Write-ColorOutput "    Файл: $($e.LogFileName)" "Gray"
            $msgShort = if ($e.Message.Length -gt 200) { $e.Message.Substring(0, 200) + "..." } else { $e.Message }
            Write-ColorOutput "    Сообщение: $msgShort" "White"
            $i++
        }
        if ($allEvents.Count -gt 10) { Write-ColorOutput "`n... и еще $($allEvents.Count - 10) событий" "Yellow" }
    }
    
    # Статистика
    Write-ColorOutput "`n📊 СТАТИСТИКА:" "Yellow"
    
    Write-ColorOutput "`n🏆 Топ EventID:" "Green"
    $topEvents = $allEvents | Group-Object EventID | Sort-Object Count -Descending | Select-Object -First 10
    $counter = 1
    foreach ($g in $topEvents) {
        $percent = [math]::Round(($g.Count / $allEvents.Count) * 100, 2)
        Write-ColorOutput "  $counter. EventID $($g.Name): $($g.Count) ($percent%)" "Cyan"
        $counter++
    }
    
    Write-ColorOutput "`n📊 Распределение по уровням:" "Green"
    $levelDist = $allEvents | Group-Object Level | Sort-Object Count -Descending
    foreach ($g in $levelDist) {
        $percent = [math]::Round(($g.Count / $allEvents.Count) * 100, 2)
        $color = switch ($g.Name) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            "Critical" { "DarkRed" }
            default { "Green" }
        }
        Write-ColorOutput "  • $($g.Name): $($g.Count) ($percent%)" $color
    }
    
    # Экспорт
    if ($ExportCSV) {
        $exportDir = if ($ExportPath) { $ExportPath } else { 
            if ($isFile) { Split-Path $LogPath -Parent } else { $LogPath }
        }
        
        if (-not (Test-Path $exportDir)) {
            New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $baseName = if ($isFile) { [IO.Path]::GetFileNameWithoutExtension($LogPath) } else { "LogAnalysis" }
        
        Write-ColorOutput "`n💾 Экспорт результатов..." "Cyan"
        Export-ToCSV -Data $allEvents -FilePath (Join-Path $exportDir "${baseName}_${timestamp}.csv")
        Export-ToHTML -Data $allEvents -FilePath (Join-Path $exportDir "${baseName}_${timestamp}.html") -SearchText $SearchText
        Write-ColorOutput "`n📂 Файлы сохранены в: $exportDir" "Green"
    }
    
    Write-ColorOutput "`n✅ Анализ завершен!" "Green"
}
catch {
    Write-ColorOutput "`n❌ Критическая ошибка: $($_.Exception.Message)" "Red"
    Write-ColorOutput "📍 Стек: $($_.ScriptStackTrace)" "Red"
    exit 1
}