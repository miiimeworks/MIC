# MIIIME Icon Changer (MIC™)

MIIIMEIconChanger · 미메아이콘체인저

![OS](https://img.shields.io/badge/Platform-Windows-0078D4?logo=windows&style=flat-square)
[![Language](https://img.shields.io/badge/Language-AutoIt-orange?logo=autoit&style=flat-square)](https://www.autoitscript.com/site/)
![License](https://img.shields.io/badge/License-Freeware-lightgrey?style=flat-square)

<br>
<img width="559" height="136" alt="001" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Enhanced/Id/Neon/4b_136_1_G.png?raw=true" style="margin-top: 20px; margin-bottom: 20px;">
<br>

A tool to extract or replace the icon (.ico) of an executable file (.exe).   
Icons are extracted via Win32 API; icon replacement works based on ResourceHacker.

실행 파일(.exe)의 아이콘(.ico)을 추출하거나 교체하는 도구입니다.  
아이콘 추출은 Win32 API로, 아이콘 교체는 ResourceHacker를 기반으로 작동합니다.

<br>
<img width="475" height="180" alt="001" src="https://github.com/miiimeworks/MIC/blob/main/Preview/001.png?raw=true" style="margin-top: 20px; margin-bottom: 20px;">  
<br>

---

## Configuration

### 1. Setup

- Download **[ResourceHacker]** and place it in the `App/ResourceHacker/` path. (Required for icon replacement only)  
- [ResourceHacker]를 다운받아 `App/ResourceHacker/` 경로에 배치. (아이콘 교체에만 필요)

### 2. Directory Structure

```text
MIIIMEIconChanger/
 │
 ├─ MIIIMEIconChanger.exe         # Executable /  실행 파일
 ├─ MIIIMEIconChanger.ini         # Configuration /  설정 파일
 │
 └─ App/                          
    └─ ResourceHacker/            # ResourceHacker.exe / 리소스해커
```

---

## How to Use

1. Select or drag the executable file you wish to modify into the **[EXE File]** input field.  
2. Select the new icon file to be applied in the **[ICO File]** input field.  
3. Click the **[Change Icon]** button.  
* You can input both the executable and icon files by dragging and dropping them directly into the GUI window.  
* The ResourceHacker executable must be present in the `App\ResourceHacker\` folder to replace icons. (Not required for extraction)
1. [EXE 파일 입력란]에 아이콘을 바꿀 실행 파일을 선택하거나 드래그.  
2. [ICO 파일 입력란]에 적용할 새로운 아이콘 파일을 선택.  
3. [Change Icon] 버튼을 클릭.  
* 실행 파일과 아이콘 파일을 GUI 창으로 직접 드래그 앤 드롭하여 입력할 수 있음.  
* 아이콘 교체를 위해서는 `App\ResourceHacker\` 폴더 내에 실행 파일이 반드시 존재해야 함. (추출에는 불필요)

---

## Features

### Extract Icon

Extracts the icon(s) embedded in an EXE file and saves them as `.ico` files.  
EXE 파일에 내장된 아이콘을 추출하여 `.ico` 파일로 저장.

Reads the EXE directly through the Win32 API (`EnumResourceNamesW`) without any external tool, so extraction is nearly instant for any EXE.  
외부 도구 없이 Win32 API(`EnumResourceNamesW`)로 EXE를 직접 읽으므로 어떤 EXE든 거의 즉시 추출.

### Change Icon

Replaces the icon embedded in an EXE file with a specified `.ico` file using ResourceHacker.  
ResourceHacker를 사용하여 EXE 파일에 내장된 아이콘을 지정한 `.ico` 파일로 교체.

### Change Description & ProductName

Updates the **FileDescription** & **ProductName** fields to match the filename (without extension) after the icon is replaced.  
아이콘 교체 후 EXE의 **FileDescription**, **ProductName** 필드를 파일명(확장자 제외)과 동일하게 변경.

---

## INI Configuration Reference

Settings are stored in `MIIIMEIconChanger.ini`. The file is auto-created with defaults on first launch.  
설정은 `MIIIMEIconChanger.ini`에 저장됨. 최초 실행 시 기본값으로 자동 생성.

### [ExtractConfig]

| Key              | Values    | Default | Description                                                                                                         |
|:---------------- |:--------- |:-------:|:------------------------------------------------------------------------------------------------------------------- |
| `NamingRule`     | `1` / `2` | `2`     | `1` = Save as resource ID name (e.g., `MAINICON.ico`)<br>`2` = Save based on EXE filename (e.g., `AppName_001.ico`) |
| `ExtractMethod`  | `1` / `2` | `2`     | `1` = Extract all icons<br>`2` = Extract first icon only                                                            |
| `SaveMethod`     | `1` / `2` | `1`     | `1` = Auto-save in the same folder as the EXE<br>`2` = Manually specify the save path (dialog)                      |

### [Options]

| Key                  | Values          | Default | Description                                                      |
|:-------------------- |:--------------- |:-------:|:---------------------------------------------------------------- |
| `BackupBeforeChange` | `0` / `1`       | `1`     | `1` = Create `.bak` backup before replacing icon                 |
| `ChangeDescription`  | `0` / `1`       | `0`     | `1` = Update FileDescription to match filename after icon change |
| `ChangeProductName`  | `0` / `1`       | `0`     | `1` = Update ProductName to match filename after icon change     |
| `LogLevel`           | `0` / `1` / `2` | `0`     | `0` = Disabled · `1` = INFO/WARN/ERROR · `2` = All (+ DEBUG)     |

### [Advanced]

| Key               | Default   | Description                                                              |
|:----------------- |:---------:|:------------------------------------------------------------------------ |
| `LogRotationSize` | `5242880` | Max log file size in bytes (5 MB). Rotates to `.log.old` when exceeded.  |

---

## Technical Notes

### 1. Automatic Backup System

Before replacing an icon, a backup copy is created as `<filename>.exe.bak` in the same directory.  
If backup creation fails due to permission issues, a warning message is displayed and the operation is aborted.  

**[자동 백업 시스템]**  
아이콘 교체 전 동일 위치에 `<파일명>.exe.bak` 파일로 원본을 복사.  
권한 문제로 백업 생성이 실패할 경우 경고 메시지를 표시하고 작업을 중단.

### 2. Icon Extraction — Win32 API

Loads the EXE as a read-only data file and enumerates icon groups with `EnumResourceNamesW(RT_GROUP_ICON)`.  
Each group's `RT_ICON` images are assembled into a standard `.ico` file directly. The enumeration order (named resources first, then numeric IDs ascending) defines the "first icon".

**[아이콘 추출 — Win32 API]**  
EXE를 읽기 전용 데이터 파일로 로드하고 `EnumResourceNamesW(RT_GROUP_ICON)`로 아이콘 그룹을 열거.  
각 그룹의 `RT_ICON` 이미지를 직접 조립하여 표준 `.ico` 파일로 저장. 열거 순서(문자열 이름 우선, 이후 숫자 ID 오름차순)가 "첫 번째 아이콘"의 기준.

### 3. Change Description & ProductName — Win32 API Patch

Patches the `FileDescription`  & `ProductName` fields directly in the `VERSIONINFO` binary resource using Win32 API calls (`BeginUpdateResource` / `UpdateResource` / `EndUpdateResource`).  

**[파일 설명, 제품 이름 교체  — Win32 API 패치]**  
Win32 API(`BeginUpdateResource` / `UpdateResource` / `EndUpdateResource`)를 직접 호출하여 `VERSIONINFO` 바이너리 리소스 내 `파일 설명`, `제품 이름` 필드를 패치.  

---

## 🛡️ Security & Anti-virus Info

### [✅ VirusTotal Analysis Report](https://www.virustotal.com/gui/file/4c10ab1f169a1f1a9d4d2e213ea2ade0bf074dd6e7dbeccb4c04dbb139b0a7b8?nocache=1)

| Status             | Details                                                                        |
|:------------------ |:------------------------------------------------------------------------------ |
| **Major Vendors**  | **Clean** (Passed by AhnLab V3, Kaspersky, Avast, ESET, etc.)                  |
| **Detection Rate** | **6 / 72** (Mostly Heuristic/Generic/Trojan-type flags)                        |
| **Integrity**      | Private project; verified via hashes and VT results. 						  |

> This program was created with AutoIt. Some antivirus programs may incorrectly detect it as a virus.  
> 본 프로그램은 AutoIt으로 제작되었습니다. 일부 백신이 바이러스로 오진할 수 있습니다.

**File Checksum (SHA-256):** `4c10ab1f169a1f1a9d4d2e213ea2ade0bf074dd6e7dbeccb4c04dbb139b0a7b8`

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
**Last Update** : 2026-10-30   

<br>
<img width="64" height="64" alt="002" src="https://github.com/miiimeworks/M4T/blob/main/4bit_Brutal/Logo/Neon/4b_Mium_64_0_G.png?raw=true">  
<br>
<br>
<br>