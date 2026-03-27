# 🔍 Windows Logs Analyzer

[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078d7.svg)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange.svg)](https://github.com/xameleon48/Windows-Logs-Analyzer)

> **Мощный PowerShell инструмент для анализа Windows логов (.evtx)**  
> Поиск по тексту, IP, процессам, временным диапазонам. Экспорт в CSV/HTML с поддержкой кириллицы. Параллельная обработка до 16 потоков.

---

## 📋 Содержание

- [✨ Возможности](#-возможности)
- [🚀 Быстрый старт](#-быстрый-старт)
- [📖 Полная документация](#-полная-документация)
  - [Основные параметры](#-основные-параметры)
  - [Поиск по содержимому](#-поиск-по-содержимому)
  - [Временные фильтры](#-временные-фильтры)
  - [Производительность](#-производительность)
  - [Управление выводом](#-управление-выводом)
  - [Очистка пустых файлов](#-очистка-пустых-файлов)
- [💡 Примеры использования](#-примеры-использования)
- [⚡ Советы по производительности](#-советы-по-производительности)
- [🔧 Устранение проблем](#-устранение-проблем)
- [📥 Установка](#-установка)
- [📄 Форматы вывода](#-форматы-вывода)
- [🤝 Вклад в проект](#-вклад-в-проект)
- [📝 Лицензия](#-лицензия)

---

## ✨ Возможности

| Функция | Описание |
|---------|----------|
| 🔍 **Поиск** | По тексту, IP-адресам, именам процессов |
| ⏰ **Временные фильтры** | Конкретный период, последние N часов/дней, сегодня/вчера |
| 📊 **Фильтрация** | По EventID, уровню событий, имени журнала |
| ⚡ **Параллельная обработка** | До 16 потоков для максимальной скорости |
| 🗑️ **Очистка** | Удаление пустых файлов логов |
| 📄 **Экспорт** | CSV и HTML с поддержкой кириллицы (UTF-8 BOM) |
| 📈 **Статистика** | Топ EventID, распределение по уровням |
| 🎨 **Подсветка** | Найденного текста в консоли и HTML |
| 🔧 **Таймауты** | На проблемные файлы |

---

## 🚀 Быстрый старт

Всего несколько команд для начала работы:

# 1️⃣ Поиск в одном файле
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Security.evtx" -SearchText "192.168.1.100"

# 2️⃣ Поиск в папке с экспортом
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "error" -ExportCSV

# 3️⃣ Поиск за последние 24 часа с параллельной обработкой
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "powershell.exe" -LastHours 24 -UseParallel -MaxThreads 8

# 4️⃣ Очистка пустых файлов (просмотр)
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -CleanEmptyLogs -DryRun

# 5️⃣ Справка
.\Analyze-Logs.ps1 -Help

---

## 📥 Установка

# Способ 1: Клонировать репозиторий (рекомендуется)
git clone https://github.com/xameleon48/Windows-Logs-Analyzer.git
cd Windows-Logs-Analyzer
.\install.ps1

# Способ 2: Скачать напрямую
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/xameleon48/Windows-Logs-Analyzer/main/Analyze-Logs.ps1" -OutFile "Analyze-Logs.ps1"

# Способ 3: Сделать алиас (после установки)
analyze-logs -LogPath "C:\Logs" -SearchText "error"

# Требования:
# - Windows 7/8/10/11 или Windows Server 2012+
# - PowerShell 5.1 или выше
# - Права на чтение файлов .evtx

---

## 📖 Полная документация


# 📌 Основные параметры
# -LogPath <путь>          # Путь к файлу .evtx или папке с логами (обязательный)
# -Help                    # Показать справку

# 🔍 Поиск по содержимому
# -SearchText <текст>      # Поиск по тексту в сообщении
# -SearchIP <IP>           # Поиск по IP-адресу
# -SearchProcess <процесс> # Поиск по имени процесса (например, powershell.exe)
# -EventID <ID>            # Поиск по EventID (можно несколько: 4624,4625)
# -Level <уровень>         # Уровень: Error, Warning, Information, Critical, Verbose
# -LogName <имя>           # Имя файла журнала (можно несколько: Security,Application)

# ⏰ Временные фильтры
# -StartTime <дата/время>  # Начало периода (формат: "2024-03-19 17:00:00")
# -EndTime <дата/время>    # Конец периода
# -LastHours <часы>        # За последние N часов
# -LastDays <дни>          # За последние N дней
# -Today                   # Только за сегодня
# -Yesterday               # Только за вчера
# -ThisHour                # Только за текущий час

# ⚡ Производительность
# -UseParallel             # Включить параллельную обработку
# -MaxThreads <число>      # Количество потоков (по умолч. 4)
# -TimeoutSeconds <сек>    # Таймаут на файл (по умолч. 30)

# 📄 Управление выводом
# -ExportCSV               # Экспорт в CSV и HTML
# -ExportPath <путь>       # Путь для экспорта (по умолч. папка с логами)
# -ShowSummary             # Показать только сводку без деталей
# -MaxEvents <число>       # Максимум событий для обработки (по умолч. 100000)

# 🗑️ Очистка пустых файлов
# -CleanEmptyLogs          # Очистить пустые файлы логов
# -DryRun                  # Показать что будет удалено без реального удаления
# -MinFileSizeKB <KB>      # Минимальный размер файла (по умолч. 10 KB)

---

## 💡 Примеры использования

# 1️⃣ Базовый поиск
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Application.evtx" -SearchText "Ошибка"
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "error" -ExportCSV
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Security.evtx" -SearchIP "192.168.1.100"
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchProcess "powershell.exe"

# 2️⃣ Временные фильтры
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "powershell.exe" -LastHours 24
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchIP "192.168.1.100" -LastDays 7
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -EventID "4624,4625" -StartTime "2024-03-19" -EndTime "2024-03-20"
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -Level Error -Today
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -Level Warning -Yesterday

# 3️⃣ Параллельная обработка
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "seadm" -UseParallel -MaxThreads 8 -ExportCSV
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "error" -UseParallel -MaxThreads 6 -TimeoutSeconds 60

# 4️⃣ Комбинированные фильтры
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchProcess "powershell.exe" -LastDays 7 -ExportCSV
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -Level Error -LastHours 24 -LogName "Application,System"
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchIP "192.168.1.100" -EventID "4625" -LastDays 30

# 5️⃣ Очистка пустых файлов
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -CleanEmptyLogs -DryRun
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -CleanEmptyLogs -MinFileSizeKB 5
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -CleanEmptyLogs

# 6️⃣ Анализ безопасности
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Security.evtx" -EventID "4625" -LastDays 7 -ExportCSV
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Security.evtx" -SearchText "seadm" -EventID "4624" -LastDays 30
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Security.evtx" -EventID "4688" -SearchProcess "powershell.exe" -LastDays 7

# 7️⃣ Расследование инцидента
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "seadm" -LastDays 30 -ExportCSV
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Security.evtx" -EventID "4625" -LastDays 7 -ExportCSV
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchProcess "powershell.exe" -LastDays 7 -ExportCSV

# 8️⃣ Автоматизация
$date = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -Level Error -StartTime $date -ExportCSV -ExportPath "C:\Reports"
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -Level "Error,Warning" -LastDays 7 -ExportCSV -ShowSummary
$lastHour = (Get-Date).AddHours(-1)
.\Analyze-Logs.ps1 -LogPath "C:\Logs\Security.evtx" -EventID "4625" -StartTime $lastHour -ExportCSV -ShowSummary

---

## 🔧 Устранение проблем

# ❌ Зависает на больших файлах
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "error" -TimeoutSeconds 15

# ❌ Не находит события с временными фильтрами
# Вместо StartTime/EndTime используйте LastDays
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "error" -LastDays 30

# ❌ Ошибка "Access Denied"
# Запустите PowerShell от имени администратора

# ❌ Кириллица в CSV отображается кракозябрами
# Используйте HTML версию или откройте CSV в Excel с выбором UTF-8

# ❌ Слишком медленная обработка
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "error" -UseParallel -MaxThreads 8 -LastDays 7

# ❌ Ошибка памяти
.\Analyze-Logs.ps1 -LogPath "C:\Logs" -SearchText "error" -MaxThreads 4 -MaxEvents 10000

---

## 📄 Форматы вывода


# CSV файл
# - Разделитель: точка с запятой (;)
# - Кодировка: UTF-8 с BOM
# - Поля: Время, Журнал, EventID, Уровень, Провайдер, Сообщение

# HTML файл
# - Удобная таблица с сортировкой
# - Подсветка найденного текста
# - Адаптивный дизайн
# - Поддержка кириллицы
# - Всплывающие подсказки для длинных имен