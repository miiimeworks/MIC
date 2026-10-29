========================================================================
             MIIIME Icon Changer (MIC™)
========================================================================

A tool to extract or replace the icon (.ico) of an executable file (.exe).   
Icons are extracted via Win32 API; icon replacement works based on ResourceHacker.

실행 파일(.exe)의 아이콘(.ico)을 추출하거나 교체하는 GUI 도구입니다.  
아이콘 추출은 Win32 API로, 아이콘 교체는 ResourceHacker를 기반으로 작동합니다.  

========================================================================
[Configuration]
========================================================================

1. Setup
   - Download [ResourceHacker] and place it in the App/ResourceHacker/ path. (Required for icon replacement only)
   - [ResourceHacker]를 다운받아 App/ResourceHacker/ 경로에 배치. (아이콘 교체에만 필요)
   
========================================================================
2. Directory Structure 
========================================================================

MIIIMEIconChanger2
 │
 ├─ MIIIMEIconChanger2.exe 		# Executable /  실행 파일
 ├─ MIIIMEIconChanger2.ini		# Configuration /  설정 파일
 │
 └─ App/                  			# Core Files  / 핵심 파일
 	   └─ ResourceHacker/ 		# ResourceHacker.exe / 리소스해커

========================================================================
[How to Use]
========================================================================

1. Select or drag the executable file you wish to modify into the **[EXE File]** input field.  
2. Select the new icon file to be applied in the **[ICO File]** input field.  
3. Click the **[Replace Icon]** button.  
4. After the process is complete, verify the newly created **"_backup.exe"** file. 
* You can input both the executable and icon files by dragging and dropping them directly into the GUI window.  
* The ResourceHacker executable must be present in the `[App\ResourceHacker]` folder to replace icons. (Not required for extraction)

1. EXE 파일 입력란]에 아이콘을 바꿀 실행 파일을 선택하거나 드래그.  
2. ICO 파일 입력란]에 적용할 새로운 아이콘 파일을 선택.  
3. [아이콘 교체 실행] 버튼을 클릭.  
4. 작업 완료 후 생성된 "_backup.exe" 파일을 확인.  
* 실행 파일과 아이콘 파일을 GUI 창으로 직접 드래그 앤 드롭하여 입력할 수 있음.
* 아이콘 교체를 위해서는 [App\ResourceHacker] 폴더 내에 실행 파일이 반드시 존재해야 함. (추출에는 불필요)

========================================================================
[Technical Notes]
========================================================================

1. Automatic Backup System 
Before replacing an icon, a backup copy is created as `<filename>.exe.bak` in the same directory.  
If backup creation fails due to permission issues, a warning message is displayed and the operation is aborted.  

[자동 백업 시스템]
아이콘 교체 전 동일 위치에 `<파일명>.exe.bak` 파일로 원본을 복사.  
권한 문제로 백업 생성이 실패할 경우 경고 메시지를 표시하고 작업을 중단.

2. Icon Extraction — Win32 API
Reads the EXE as a read-only data file and enumerates icon groups with `EnumResourceNamesW(RT_GROUP_ICON)`.  
Each group's `RT_ICON` images are assembled into a standard `.ico` file directly, so no external tool is needed 
and extraction completes almost instantly. The enumeration order (named resources first, then numeric IDs ascending) 
defines the "first icon".

[아이콘 추출 — Win32 API]
EXE를 읽기 전용 데이터 파일로 로드하고 `EnumResourceNamesW(RT_GROUP_ICON)`로 아이콘 그룹을 열거.  
각 그룹의 `RT_ICON` 이미지를 직접 조립하여 표준 `.ico` 파일로 저장하므로 외부 도구가 필요 없으며 거의 즉시 완료.  
열거 순서(문자열 이름 우선, 이후 숫자 ID 오름차순)가 "첫 번째 아이콘"의 기준.

3. Change Description & ProductName — Win32 API Patch 
Patches the `FileDescription` & `ProductName` fields directly in the `VERSIONINFO` binary resource using Win32 API calls 
(`BeginUpdateResource` / `UpdateResource` / `EndUpdateResource`).  

[파일 설명, 제품 이름 교체 — Win32 API 패치]  
Win32 API(`BeginUpdateResource` / `UpdateResource` / `EndUpdateResource`)를 직접 호출하여 
`VERSIONINFO` 바이너리 리소스 내 `파일 설명`, `제품 이름` 필드를 패치.  

______________________________________________________________________________________________________________________

This program was created with AutoIt. Some antivirus programs may incorrectly detect it as a virus.
본 프로그램은 AutoIt으로 제작되었습니다. 일부 백신이 바이러스로 오진 할 수 있습니다.

========================================================================
[Disclaimer]
========================================================================

Provided "AS IS", without warranty.
This is a private project. No technical support is provided.
본 프로그램은 "있는 그대로" 제공되며, 사용 중 발생하는 문제에 대해 제작자는 책임을 지지 않습니다.
기술 지원은 제공되지 않습니다.

Developer	: MIIIME 
Website		: https://www.miiime.com 
GitHub		: @miiimeworks 
Update		: 2026.10.30
