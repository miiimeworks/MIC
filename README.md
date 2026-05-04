# MIIIME Icon Changer (MIC™)

MIIIMEIconChanger · 미메아이콘체인저

![OS](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows&style=flat-square)
[![Language](https://img.shields.io/badge/Language-AutoIt-orange?logo=autoit&style=flat-square)](https://www.autoitscript.com/site/)
![License](https://img.shields.io/badge/License-Freeware-lightgrey?style=flat-square)

<br>
<img width="559" height="136" alt="001" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Enhanced/Id/Neon/4b_136_1_G.png?raw=true" style="margin-top: 20px; margin-bottom: 20px;">
<br>

A tool to extract or replace the icon (.ico) of an executable file (.exe).   
It works based on ResourceHacker.

실행 파일(.exe)의 아이콘(.ico)을 추출하거나 교체하는 도구입니다.  
ResourceHacker를 기반으로 작동합니다.

<br>
<img width="475" height="179" alt="001" src="https://github.com/miiimeworks/MIC/blob/main/Preview/001.png?raw=true" style="margin-top: 20px; margin-bottom: 20px;">  
<br>

---

## Configuration

### 1. Setup

- Download **[ResourceHacker]** and place it in the `App/ResourceHacker/` path.  
- [ResourceHacker]를 다운받아 `App/ResourceHacker/` 경로에 배치.

### 2. Directory Structure

```text
MIIIMEIconChanger/
 │
 ├─ MIIIMEIconChanger.exe         # Executable /  실행 파일
 ├─ MIIIMEIconChanger.ini         # Configuration /  설정 파일
 │
 └─ App/                           # Core Files  / 핵심 파일
    └─ ResourceHacker/             # ResourceHacker.exe / 리소스해커
```

---

## How to Use

1. Select or drag the executable file you wish to modify into the **[EXE File]** input field.  
2. Select the new icon file to be applied in the **[ICO File]** input field.  
3. Click the **[Change Icon]** button.  
4. After the process is complete, verify the newly created **".bak"** backup file.

* You can input both the executable and icon files by dragging and dropping them directly into the GUI window.  
* The ResourceHacker executable must be present in the `App\ResourceHacker\` folder for the program to function.

1. [EXE 파일 입력란]에 아이콘을 바꿀 실행 파일을 선택하거나 드래그.  
2. [ICO 파일 입력란]에 적용할 새로운 아이콘 파일을 선택.  
3. [Change Icon] 버튼을 클릭.  
4. 작업 완료 후 생성된 ".bak" 백업 파일을 확인.

* 실행 파일과 아이콘 파일을 GUI 창으로 직접 드래그 앤 드롭하여 입력할 수 있음.  
* 프로그램 실행을 위해서는 `App\ResourceHacker\` 폴더 내에 실행 파일이 반드시 존재해야 함.

---

## Features

### Extract Icon

Extracts the icon(s) embedded in an EXE file and saves them as `.ico` files.  
EXE 파일에 내장된 아이콘을 추출하여 `.ico` 파일로 저장.

**Extraction Mode (INI: `ExtractionMode`)**

| Mode | Description |
|:----:|:------------|
| **Light** (default) | Tries only 3 standard IDs: `MAINICON`, `1`, `101`. Fast and sufficient for most standard EXEs. |
| **Deep** | Queries all existing resource IDs via `ResourceHacker -action list`, then extracts each one accurately. Falls back to smart brute-force if the query fails. Slower but handles non-standard EXEs. |

---

### Change Icon

Replaces the icon embedded in an EXE file with a specified `.ico` file using ResourceHacker.  
ResourceHacker를 사용하여 EXE 파일에 내장된 아이콘을 지정한 `.ico` 파일로 교체.

---

### Change Description

Updates the **FileDescription** field to match the filename (without extension) after the icon is replaced.  
아이콘 교체 후 EXE의 **FileDescription** 필드를 파일명(확장자 제외)과 동일하게 변경.


---

## INI Configuration Reference

Settings are stored in `MIIIMEIconChanger.ini`. The file is auto-created with defaults on first launch.  
설정은 `MIIIMEIconChanger.ini`에 저장됨. 최초 실행 시 기본값으로 자동 생성.

### [ExtractConfig]

| Key | Values | Default | Description |
|:----|:-------|:-------:|:------------|
| `NamingRule` | `1` / `2` | `2` | `1` = Save as resource ID name (e.g., `MAINICON.ico`)<br>`2` = Save based on EXE filename (e.g., `AppName_001.ico`) |
| `ExtractMethod` | `1` / `2` | `2` | `1` = Extract all icons<br>`2` = Extract first icon only |
| `SaveMethod` | `1` / `2` | `1` | `1` = Auto-save in the same folder as the EXE<br>`2` = Manually specify the save path (dialog) |
| `ExtractionMode` | `1` / `2` | `1` | `1` = Light (fast)<br>`2` = Deep (accurate, slower) |

### [Options]

| Key | Values | Default | Description |
|:----|:-------|:-------:|:------------|
| `BackupBeforeChange` | `0` / `1` | `1` | `1` = Create `.bak` backup before replacing icon |
| `ChangeDescription` | `0` / `1` | `0` | `1` = Update FileDescription to match filename after icon change |
| `LogLevel` | `0` / `1` / `2` | `0` | `0` = Disabled · `1` = INFO/WARN/ERROR · `2` = All (+ DEBUG) |

### [Advanced]

| Key | Default | Description |
|:----|:-------:|:------------|
| `LogRotationSize` | `5242880` | Max log file size in bytes (5 MB). Rotates to `.log.old` when exceeded. |
| `DeepModeGap` | `20` | Consecutive failures allowed before early stop in Deep mode brute-force. |

---

## Technical Notes

### 1. Automatic Backup System 
Before replacing an icon, a backup copy is created as `<filename>.exe.bak` in the same directory.  
If backup creation fails due to permission issues, a warning message is displayed and the operation is aborted.  

**[자동 백업 시스템]**  
아이콘 교체 전 동일 위치에 `<파일명>.exe.bak` 파일로 원본을 복사.  
권한 문제로 백업 생성이 실패할 경우 경고 메시지를 표시하고 작업을 중단.

### 2. Icon Extraction — Deep Mode
Uses `ResourceHacker -action list` to enumerate actual resource IDs before extraction.  
If ID enumeration fails, automatically falls back to a smart brute-force scan (ID range 1–500) with early termination controlled by `DeepModeGap`.

**[아이콘 추출 — Deep 모드]**  
`ResourceHacker -action list`로 실제 리소스 ID를 열거한 후 추출.  
ID 열거 실패 시 스마트 브루트포스(ID 범위 1~500, `DeepModeGap` 기반 조기 종료)로 자동 전환.

### 3. Change Description — Win32 API Patch 
Patches the `FileDescription` field directly in the `VERSIONINFO` binary resource using Win32 API calls (`BeginUpdateResource` / `UpdateResource` / `EndUpdateResource`).  

**[Change Description — Win32 API 패치]**  
Win32 API(`BeginUpdateResource` / `UpdateResource` / `EndUpdateResource`)를 직접 호출하여 `VERSIONINFO` 바이너리 리소스 내 `FileDescription` 필드를 패치.  

---

## 🛡️ Security & Anti-virus Info

### [✅ VirusTotal Analysis Report](https://www.virustotal.com/gui/file/63b4fc4ddddea8f06b16c5419ddcfb3f982143cf0342f205aadeceac42288c64?nocache=1)

| Status             | Details                                                                        |
|:------------------ |:------------------------------------------------------------------------------ |
| **Major Vendors**  | **Clean** (Passed by AhnLab V3, Kaspersky, Avast, ESET, etc.)                  |
| **Detection Rate** | **6 / 72** (Mostly Heuristic/Generic/Trojan-type flags)                       |
| **Integrity**      | The source code is transparently available for verification in this repository |

> This program was created with AutoIt. Some antivirus programs may incorrectly detect it as a virus.  
> 본 프로그램은 AutoIt으로 제작되었습니다. 일부 백신이 바이러스로 오진할 수 있습니다.

**File Checksum (SHA-256):** `63b4fc4ddddea8f06b16c5419ddcfb3f982143cf0342f205aadeceac42288c64`

---

## Disclaimer

Provided **“AS IS”**, without warranty.  
This is a **private project**. No technical support is provided.

본 프로그램은 **“있는 그대로”** 제공되며, 사용 중 발생하는 문제에 대해 제작자는 책임을 지지 않습니다.  
기술 지원은 제공되지 않습니다.

---

## Project Information

**Developer** : MIIIME  
**Website** : https://www.miiime.com  
**GitHub** : [@miiimeworks](https://github.com/miiimeworks)  
**Last Update** : 2026-05-04   

<br>
<img width="64" height="64" alt="002" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Brutal/Logo/Neon/4b_Mium_64_0_G.png?raw=true">  
<br>
<br>
<br>