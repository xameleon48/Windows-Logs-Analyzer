# 🔍 Windows Logs Analyzer

[![PowerShell Version](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Windows](https://img.shields.io/badge/Platform-Windows-0078d7.svg)](https://www.microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange.svg)](https://github.com/xameleon48/Windows-Logs-Analyzer)

> Мощный PowerShell инструмент для анализа Windows логов (.evtx) с поддержкой поиска по тексту, IP, процессам, временным диапазонам и экспортом в CSV/HTML.

## 📸 Скриншоты

### Анализ логов в консоли
![Console Output](https://via.placeholder.com/800x400?text=Console+Output+Example)

### HTML отчет
![HTML Report](https://via.placeholder.com/800x400?text=HTML+Report+Example)

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

## 📋 Требования

- ✅ Windows 7/8/10/11 или Windows Server 2012+
- ✅ PowerShell 5.1 или выше
- ✅ Права на чтение файлов .evtx

## 🚀 Быстрая установка

```powershell
# Способ 1: Скачать напрямую
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/xameleon48/Windows-Logs-Analyzer/main/Analyze-Logs.ps1" -OutFile "Analyze-Logs.ps1"

# Способ 2: Клонировать репозиторий
git clone https://github.com/xameleon48/Windows-Logs-Analyzer.git
cd Windows-Logs-Analyzer

# Способ 3: Запустить установщик (после клонирования)
.\install.ps1