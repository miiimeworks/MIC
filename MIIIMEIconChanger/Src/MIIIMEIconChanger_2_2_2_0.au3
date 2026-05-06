#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=App.ico
#AutoIt3Wrapper_Outfile=..\MIIIMEIconChanger.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=MIIIME Icon Changer
#AutoIt3Wrapper_Res_Fileversion=2.2.2.0
#AutoIt3Wrapper_Res_ProductName=MIIIME Icon Changer
#AutoIt3Wrapper_Res_ProductVersion=2.2.2.0
#AutoIt3Wrapper_Res_LegalCopyright=MIIIME
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; [수정 2.2.2.0]
; - ChangeProductName 기능 추가
;   · [Options] ChangeProductName INI 키 연동 (0/1)
;   · GUI 체크박스($Chk_ProdName) 추가 — Description 체크박스 우측 배치
;   · _PatchProductName() 함수 신규 도입 (_PatchFileDescription 과 동일 구조, ProductName 마커 사용)
;   · $bDoProd 플래그로 독립 실행 (아이콘/Description 결과와 무관)
; - 결과 메시지 형식 변경
;   · [Change Success] / [Change Failed] 섹션으로 구조화
;   · 해당 항목만 표시 (성공 항목만 있으면 [Change Failed] 섹션 생략, 반대도 동일)
; - $lbl_Status 텍스트를 새 항목 조합에 맞게 갱신

; [수정 2.2.1.0]
; - 아이콘 실패 / Description 성공 케이스 추가
;   · 기존: 아이콘 교체 실패 시 ContinueLoop → Description 패치 기회 없음
;   · 변경: 아이콘 실패 후에도 Description 패치를 독립적으로 실행
; - 결과 메시지를 8가지 조합으로 완전 분기
;   Icon only      OK         → "Icon changed successfully."
;   Icon only      FAIL       → "Failed to change icon."
;   Desc only      OK         → "Description updated successfully."
;   Desc only      FAIL       → "Description update failed."
;   Icon + Desc    OK / OK    → "Icon and Description changed successfully."
;   Icon + Desc    OK / FAIL  → Partial: "Icon OK / Description failed."
;   Icon + Desc    FAIL / OK  → Partial: "Icon failed / Description updated."
;   Icon + Desc    FAIL / FAIL → "Icon and Description both failed."
; - $bIconOK 초기값 True → False 로 수정 (미실행 시 성공 오판 방지)

; [수정 2.2.0.0]
; - ICO 미지정 상태에서 Change Description 단독 실행 지원
;   · 기존: ICO 없으면 무조건 에러 → 종료
;   · 변경: ICO 없고 ChangeDescription=1 이면 Description만 패치 후 완료
;   · ICO 없고 ChangeDescription=0 이면 "Nothing to do" 경고
; - 성공 메시지 3종 분기
;   · 아이콘만 교체          → "Icon changed successfully."
;   · Description만 변경     → "Description updated successfully."
;   · 아이콘 + Description   → "Icon and Description changed successfully."
;   · 아이콘 OK / Desc 실패  → WARN 메시지로 부분 성공 안내
; - ICO 교체 시에만 RH 존재 여부 검사 (Desc 단독 실행 시 RH 불필요)
; - $bDoIcon / $bDoDesc 플래그로 로직 명시적 분리

; - Change Description 구현 방식 전면 교체 (RH 방식 제거 → Win32 API 직접 패치)
;   · RH는 -res에 .rc 텍스트를 받지 못함(-res는 바이너리 전용) → addoverwrite 조용히 실패
;   · _PatchFileDescription() 함수 신규 도입:
;       Step1: LoadLibraryEx(LOAD_LIBRARY_AS_DATAFILE) + FindResource/LoadResource/LockResource
;              → VERSIONINFO 바이너리 획득
;       Step2: UTF-16LE 이진 마커("FileDescription\0") 탐색
;       Step3: 값 영역을 새 이름으로 in-place 덮어쓰기 (기존 값 길이 범위 내)
;       Step4: BeginUpdateResource → UpdateResource(RT_VERSION,1,0x0409) → EndUpdateResource
;   · 외부 툴·임시 파일 불필요, 순수 Win32 API DllCall 처리
;   · 각 Step 결과를 DEBUG 로그로 기록하여 진단 가능

; [수정 2.0.9.0]
; - Change Description 기능 추가 (RH 기반, 2.1.0.0에서 Win32 API 방식으로 교체됨)
;   · [Options] ChangeDescription INI 키 연동 (0/1)
;   · GUI 체크박스($Chk_Desc) 추가 — DeepMode 체크박스 하단 배치
;   · 창 높이 150 → 175 로 조정

; [수정 2.0.8.0]
; - 중복된 #Region 블록(2번째) 삭제
; - _Extract_Light() 데드코드 함수 삭제
; - _Log() 내부 불필요한 $g_iLogLevel > 1 가중치 블록 제거 및 로직 단순화
; - 체크박스($Chk_Deep) 관련 주석 불일치 정리 (체크박스 방식으로 명확히 통일)
; - INI 초기 생성값 ExtractMethod "1"->"2", BackupBeforeChange "0"->"1" 로 INI 파일 기본값과 일치
; - _RH_GetIconGroupIDs() 헤더 배열 주석에 대소문자 정규화 처리 명시

#NoTrayIcon
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <SendMessage.au3>
#include <WinAPIGdi.au3>
#include <GuiEdit.au3>

Opt('MustDeclareVars', 1)

; =================================================================================================
; [Theme] MIIIME 다크·각진 테마 함수 블록
; =================================================================================================

Func _ApplySquareCorners($hWnd)
    DllCall("dwmapi.dll", "long", "DwmSetWindowAttribute", _
        "hwnd", $hWnd, "dword", 33, "dword*", 1, "dword", 4)
EndFunc

Func _DisableTheme($hCtrl)
    DllCall("uxtheme.dll", "int", "SetWindowTheme", _
        "hwnd", $hCtrl, "wstr", "", "wstr", "")
EndFunc

Func _MsgBoxSquare($iType, $sTitle, $sText)
    Local $hMsgGUI = GUICreate($sTitle, 400, 170, -1, -1, BitOR($WS_CAPTION, $WS_POPUP), $WS_EX_TOPMOST)
    GUISetFont(10, 400, 0, "", $hMsgGUI)
    GUISetBkColor(0x212121, $hMsgGUI)
    _ApplySquareCorners($hMsgGUI)

    Local $iTextColor = 0xE0E0E0
    If $iType = 16 Then $iTextColor = 0xFF5252
    If $iType = 48 Then $iTextColor = 0xFFD740

    Local $lblMsg = GUICtrlCreateLabel($sText, 20, 20, 360, 90)
    GUICtrlSetColor($lblMsg, $iTextColor)
    GUICtrlSetBkColor($lblMsg, 0x212121)

    Local $btnOk = GUICtrlCreateButton("OK", 160, 125, 80, 28)
    _DisableTheme(GUICtrlGetHandle($btnOk))
    GUICtrlSetState($btnOk, $GUI_FOCUS)

    GUISetState(@SW_SHOW, $hMsgGUI)
    While 1
        Local $mMsg = GUIGetMsg()
        If $mMsg = $GUI_EVENT_CLOSE Or $mMsg = $btnOk Then ExitLoop
    WEnd
    GUIDelete($hMsgGUI)
EndFunc

Func _SetInputPadding($hInput, $iTopPadding)
    Local $tRect = DllStructCreate($tagRECT)
    DllStructSetData($tRect, "Left", 5)
    DllStructSetData($tRect, "Top", $iTopPadding)
    DllStructSetData($tRect, "Right", 264 - 5)
    DllStructSetData($tRect, "Bottom", 25)
    _SendMessage($hInput, $EM_SETRECT, 0, DllStructGetPtr($tRect))
EndFunc

; =================================================================================================
; [Log] MIIIME 로그 표준 (_Log 함수)
; =================================================================================================

Global $g_sLogFile    = @ScriptDir & "\" & StringRegExpReplace(@ScriptName, "(?i)\.(au3|exe)$", "") & ".log"
Global $g_iLogLevel   = 0
Global $g_iLogRotSize = 5242880

; LogLevel 동작:
;   0 = 로그 비활성화 (아무것도 기록하지 않음)
;   1 = INFO / WARN / ERROR 기록 (DEBUG 제외)
;   2 = 전체 기록 (DEBUG 포함)
Func _Log($sSender, $sMsg, $sLevel = "INFO")
    If $g_iLogLevel = 0 Then Return
    If $g_iLogLevel = 1 And $sLevel = "DEBUG" Then Return
    ; LogLevel=2 이면 모든 레벨 통과

    If $g_iLogRotSize <= 0 Then $g_iLogRotSize = 5242880

    If FileExists($g_sLogFile) And FileGetSize($g_sLogFile) > $g_iLogRotSize Then
        If Not StringInStr(FileGetAttrib($g_sLogFile), "R") Then
            FileMove($g_sLogFile, $g_sLogFile & ".old", 1)
        EndIf
    EndIf

    Local $sTime = @YEAR & "/" & @MON & "/" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    Local $sLine = "[" & $sTime & "] [" & StringUpper($sLevel) & "] [" & $sSender & "] " & $sMsg

    Local $hFile
    Local $iTry = 0
    While $iTry < 5
        $hFile = FileOpen($g_sLogFile, 1)
        If $hFile <> -1 Then
            FileWriteLine($hFile, $sLine)
            FileClose($hFile)
            Return
        EndIf
        Sleep(50)
        $iTry += 1
    WEnd
EndFunc

; =================================================================================================
; [Core] Deep 모드 Step1 - ResourceHacker -action list 로 실제 ICONGROUP ID 조회
; -------------------------------------------------------------------------------------------------
; RH 버전별 출력 형식 대응:
;   패턴 A: "MAINICON,"           (구버전)
;   패턴 B: "  MAINICON, 0x0409," (최신버전 - 언어코드 포함)
; 섹션 헤더 비교는 $sLine을 StringUpper() 처리 후 수행하므로
;   아래 $aHeaders 배열은 모두 대문자로 정의합니다.
;   대응 헤더: [ICONGROUP] / [GROUPICON] / [RT_GROUP_ICON] / [GROUP_ICON]
;
; 반환값: [0]=개수, [1..n]=ID 문자열. 실패 시 [0]=0
; =================================================================================================
Func _RH_GetIconGroupIDs($sRH_Path, $sExePath)
    Local $sTmpList = @TempDir & "\MIC_rh_list_" & @AutoItPID & ".txt"

    RunWait(StringFormat('"%s" -open "%s" -save "%s" -action list', _
        $sRH_Path, $sExePath, $sTmpList), "", @SW_HIDE)

    Local $aResult[1]
    $aResult[0] = 0

    If Not FileExists($sTmpList) Then
        _Log("MIC", "[GetIDs] List file not created.", "WARN")
        Return $aResult
    EndIf

    Local $sContent = FileRead($sTmpList)
    FileDelete($sTmpList)

    If $sContent = "" Then
        _Log("MIC", "[GetIDs] List file is empty.", "WARN")
        Return $aResult
    EndIf

    _Log("MIC", "[GetIDs] Raw list (first 300): " & StringLeft($sContent, 300), "DEBUG")

    Local $aLines       = StringSplit($sContent, @LF, 1)
    Local $bInIconGroup = False
    Local $aIDs[64]
    Local $iFound       = 0

    ; 모두 대문자로 정의 — 비교 시 StringUpper($sLine)과 직접 대조
    Local $aHeaders[4] = ["[ICONGROUP]", "[GROUPICON]", "[RT_GROUP_ICON]", "[GROUP_ICON]"]

    For $li = 1 To $aLines[0]
        Local $sLine = StringStripWS(StringReplace($aLines[$li], @CR, ""), 3)
        If $sLine = "" Then ContinueLoop

        If StringLeft($sLine, 1) = "[" Then
            Local $sUpper = StringUpper($sLine)
            Local $bMatch = False
            For $hi = 0 To 3
                If $sUpper = $aHeaders[$hi] Then
                    $bMatch = True
                    ExitLoop
                EndIf
            Next
            If $bMatch Then
                $bInIconGroup = True
            Else
                If $bInIconGroup Then ExitLoop
            EndIf
            ContinueLoop
        EndIf

        If $bInIconGroup Then
            ; 쉼표로 분리 후 첫 토큰만 사용 → 언어코드(0x0409 등) 자동 제거
            Local $aParts = StringSplit($sLine, ",", 1)
            Local $sID = StringStripWS($aParts[1], 3)
            If $sID <> "" Then
                If $iFound >= UBound($aIDs) Then ReDim $aIDs[$iFound + 32]
                $aIDs[$iFound] = $sID
                $iFound += 1
                _Log("MIC", "[GetIDs] Found ID: " & $sID, "DEBUG")
            EndIf
        EndIf
    Next

    If $iFound = 0 Then
        _Log("MIC", "[GetIDs] No ICONGROUP in list.", "WARN")
        Return $aResult
    EndIf

    Local $aFinal[$iFound + 1]
    $aFinal[0] = $iFound
    For $i = 0 To $iFound - 1
        $aFinal[$i + 1] = $aIDs[$i]
    Next

    _Log("MIC", "[GetIDs] Total IDs: " & $iFound)
    Return $aFinal
EndFunc

; =================================================================================================
; [Core] Deep 모드 Step2 폴백 - 스마트 브루트포스
; -------------------------------------------------------------------------------------------------
; -action list 파싱 실패 시 사용. 1~500 범위를 시도하되
; 아이콘을 하나 이상 찾은 후 $iMaxGap 연속 실패하면 조기 종료합니다.
;
; 반환값: [0]=개수, [1..n]=ID 문자열
; =================================================================================================
Func _RH_BruteForceIDs($sRH_Path, $sExePath, $iMaxGap = 20)
    _Log("MIC", "[BruteForce] Starting (maxGap=" & $iMaxGap & ")", "WARN")

    Local $sTmpProbe = @TempDir & "\MIC_rh_probe_" & @AutoItPID & ".ico"
    Local $aIDs[64]
    Local $iFound           = 0
    Local $iConsecutiveFail = 0

    ; MAINICON 먼저
    RunWait(StringFormat('"%s" -open "%s" -save "%s" -action extract -mask ICONGROUP,MAINICON,', _
        $sRH_Path, $sExePath, $sTmpProbe), "", @SW_HIDE)
    If FileExists($sTmpProbe) And FileGetSize($sTmpProbe) > 0 Then
        $aIDs[$iFound] = "MAINICON"
        $iFound += 1
        _Log("MIC", "[BruteForce] Found: MAINICON", "DEBUG")
    EndIf
    If FileExists($sTmpProbe) Then FileDelete($sTmpProbe)

    ; 숫자 ID 1~500
    For $id = 1 To 500
        RunWait(StringFormat('"%s" -open "%s" -save "%s" -action extract -mask ICONGROUP,%s,', _
            $sRH_Path, $sExePath, $sTmpProbe, String($id)), "", @SW_HIDE)

        If FileExists($sTmpProbe) And FileGetSize($sTmpProbe) > 0 Then
            If $iFound >= UBound($aIDs) Then ReDim $aIDs[$iFound + 32]
            $aIDs[$iFound] = String($id)
            $iFound += 1
            $iConsecutiveFail = 0
            _Log("MIC", "[BruteForce] Found ID: " & $id, "DEBUG")
        Else
            $iConsecutiveFail += 1
            If $iConsecutiveFail >= $iMaxGap And $iFound > 0 Then
                _Log("MIC", "[BruteForce] Early stop at ID " & $id & " (gap=" & $iMaxGap & ")")
                ExitLoop
            EndIf
        EndIf
        If FileExists($sTmpProbe) Then FileDelete($sTmpProbe)
    Next

    If FileExists($sTmpProbe) Then FileDelete($sTmpProbe)

    Local $aFinal[$iFound + 1]
    $aFinal[0] = $iFound
    For $i = 0 To $iFound - 1
        $aFinal[$i + 1] = $aIDs[$i]
    Next

    _Log("MIC", "[BruteForce] Total: " & $iFound)
    Return $aFinal
EndFunc

; =================================================================================================
; 1. 환경 설정 및 INI 파일 처리
; =================================================================================================
Global $sRH_Path = @ScriptDir & "\App\ResourceHacker\ResourceHacker.exe"
Global $sIniPath = @ScriptDir & "\" & StringRegExpReplace(@ScriptName, "(?i)\.(au3|exe)$", "") & ".ini"

; INI가 없을 때 생성하는 기본값은 INI 파일의 주석 기재 기본값과 일치시킵니다.
;   ExtractMethod   : 2 (첫 번째 아이콘만 추출)
;   BackupBeforeChange : 1 (백업 생성)
If Not FileExists($sIniPath) Then
    IniWrite($sIniPath, "ExtractConfig", "NamingRule",         "2")
    IniWrite($sIniPath, "ExtractConfig", "ExtractMethod",      "2")
    IniWrite($sIniPath, "ExtractConfig", "SaveMethod",         "1")
    IniWrite($sIniPath, "ExtractConfig", "ExtractionMode",     "1")
    IniWrite($sIniPath, "Options",       "BackupBeforeChange", "1")
    IniWrite($sIniPath, "Options",       "ChangeDescription",  "0")
    IniWrite($sIniPath, "Options",       "ChangeProductName",  "0")
    IniWrite($sIniPath, "Options",       "LogLevel",           "0")
    IniWrite($sIniPath, "Advanced",      "LogRotationSize",    "5242880")
    IniWrite($sIniPath, "Advanced",      "DeepModeGap",        "20")
EndIf

$g_iLogLevel   = Int(IniRead($sIniPath, "Options",  "LogLevel",        "0"))
$g_iLogRotSize = Int(IniRead($sIniPath, "Advanced", "LogRotationSize", "5242880"))

Local $sSessionID = Hex(Random(0, 0xFFFF, 1), 4) & "-" & Hex(Random(0, 0xFFFF, 1), 4)
_Log("MIC", "========== [Session Started] ID: " & $sSessionID & " ==========")
_Log("MIC", "[Init] LogLevel=" & $g_iLogLevel, "DEBUG")
_Log("MIC", "[Init] RH Path: " & $sRH_Path, "DEBUG")

; =================================================================================================
; 2. 색상 팔레트 및 테마 상수
; =================================================================================================
Global Const $BG_MAIN    = 0x212121
Global Const $FG_DEFAULT = 0xE0E0E0
Global Const $FG_STATUS  = 0x888888

; =================================================================================================
; 3. 메인 GUI 생성
; =================================================================================================
Global $hGUI = GUICreate("MIIIME Icon Changer", 473, 153, -1, -1, -1, $WS_EX_ACCEPTFILES)
GUISetBkColor($BG_MAIN)
_ApplySquareCorners($hGUI)

; --- Deep 모드 체크박스 (상단) ---
; 체크박스 방식 사용. 상태는 INI ExtractionMode 값과 연동됩니다.
;   체크됨  = ExtractionMode=2 (Deep)
;   체크 해제 = ExtractionMode=1 (Light)
Global $Chk_Deep = GUICtrlCreateCheckbox("DeepMode", 20, 10, 150, 24)
_DisableTheme(GUICtrlGetHandle($Chk_Deep))
GUICtrlSetColor($Chk_Deep, $FG_DEFAULT)
GUICtrlSetBkColor($Chk_Deep, $BG_MAIN)

; INI ExtractionMode 값에 따라 초기 체크 상태 설정
Local $iInitMode = Int(IniRead($sIniPath, "ExtractConfig", "ExtractionMode", "1"))
If $iInitMode = 2 Then
    GUICtrlSetState($Chk_Deep, $GUI_CHECKED)
Else
    GUICtrlSetState($Chk_Deep, $GUI_UNCHECKED)
EndIf

; --- Change Description 체크박스 (DeepMode 하단) ---
; 아이콘 교체 시 EXE FileDescription을 파일명(확장자 제외)으로 변경 여부
;   체크됨  = ChangeDescription=1 (활성화)
;   체크 해제 = ChangeDescription=0 (비활성화)
Global $Chk_Desc = GUICtrlCreateCheckbox("Description", 20, 101, 140, 20)
_DisableTheme(GUICtrlGetHandle($Chk_Desc))
GUICtrlSetColor($Chk_Desc, $FG_DEFAULT)
GUICtrlSetBkColor($Chk_Desc, $BG_MAIN)

Local $iInitDesc = Int(IniRead($sIniPath, "Options", "ChangeDescription", "0"))
If $iInitDesc = 1 Then
    GUICtrlSetState($Chk_Desc, $GUI_CHECKED)
Else
    GUICtrlSetState($Chk_Desc, $GUI_UNCHECKED)
EndIf

; --- Change ProductName 체크박스 (Description 우측) ---
; 아이콘 교체 시 EXE ProductName을 파일명(확장자 제외)으로 변경 여부
;   체크됨  = ChangeProductName=1 (활성화)
;   체크 해제 = ChangeProductName=0 (비활성화)
;Global $Chk_ProdName = GUICtrlCreateCheckbox("ProductName", 120, 101, 140, 20)
Global $Chk_ProdName = GUICtrlCreateCheckbox("ProductName", 20, 122, 140, 20)
_DisableTheme(GUICtrlGetHandle($Chk_ProdName))
GUICtrlSetColor($Chk_ProdName, $FG_DEFAULT)
GUICtrlSetBkColor($Chk_ProdName, $BG_MAIN)

Local $iInitProd = Int(IniRead($sIniPath, "Options", "ChangeProductName", "0"))
If $iInitProd = 1 Then
    GUICtrlSetState($Chk_ProdName, $GUI_CHECKED)
Else
    GUICtrlSetState($Chk_ProdName, $GUI_UNCHECKED)
EndIf

; --- 입력창 및 버튼 ---
Global $Input_EXE = GUICtrlCreateInput("Target Executable File (.exe)", 20, 36, 264, 25, BitOR($GUI_SS_DEFAULT_INPUT, $ES_MULTILINE))
GUICtrlSetState(-1, $GUI_DROPACCEPTED)
_DisableTheme(GUICtrlGetHandle($Input_EXE))
_SetInputPadding(GUICtrlGetHandle($Input_EXE), 4)

Global $Btn_FindEXE = GUICtrlCreateButton("...", 294, 36, 40, 25)
_DisableTheme(GUICtrlGetHandle($Btn_FindEXE))

Global $Btn_Extract = GUICtrlCreateButton("Extract", 343, 36, 110, 25)
_DisableTheme(GUICtrlGetHandle($Btn_Extract))

Global $Input_ICO = GUICtrlCreateInput("Icon File to Apply (.ico)", 20, 71, 264, 25, BitOR($GUI_SS_DEFAULT_INPUT, $ES_MULTILINE))
GUICtrlSetState(-1, $GUI_DROPACCEPTED)
_DisableTheme(GUICtrlGetHandle($Input_ICO))
_SetInputPadding(GUICtrlGetHandle($Input_ICO), 4)

Global $Btn_FindICO = GUICtrlCreateButton("...", 294, 71, 40, 25)
_DisableTheme(GUICtrlGetHandle($Btn_FindICO))

Global $Btn_Run = GUICtrlCreateButton("Change", 343, 71, 110, 25)
_DisableTheme(GUICtrlGetHandle($Btn_Run))

;Global $lbl_Status = GUICtrlCreateLabel("Ready", 20, 128, 360, 17)
Global $lbl_Status = GUICtrlCreateLabel("Ready", 134, 125, 360, 17)
GUICtrlSetColor($lbl_Status, $FG_STATUS)
GUICtrlSetBkColor($lbl_Status, $BG_MAIN)

GUISetState(@SW_SHOW)

_GUICtrlEdit_SetSel(GUICtrlGetHandle($Input_EXE), -1, -1)
_GUICtrlEdit_SetSel(GUICtrlGetHandle($Input_ICO), -1, -1)

Global $sExePath = ""
Global $sIcoPath = ""

_Log("MIC", "[Init] GUI Created.", "DEBUG")

; =================================================================================================
; 4. 메인 루프
; =================================================================================================
While 1
    Local $nMsg = GUIGetMsg()
    Switch $nMsg
        Case $GUI_EVENT_CLOSE
            _Log("MIC", "========== [Session Terminated] ==========")
            Exit

        ; ------------------------------------------------------------------
        ; Deep 체크박스 상태 변경 → INI ExtractionMode 즉시 저장
        ;   체크됨    → ExtractionMode=2 (Deep)
        ;   체크 해제 → ExtractionMode=1 (Light)
        ; ------------------------------------------------------------------
        Case $Chk_Deep
            If GUICtrlRead($Chk_Deep) = $GUI_CHECKED Then
                IniWrite($sIniPath, "ExtractConfig", "ExtractionMode", "2")
                _Log("MIC", "[UI] ExtractionMode set to 2 (Deep)", "DEBUG")
            Else
                IniWrite($sIniPath, "ExtractConfig", "ExtractionMode", "1")
                _Log("MIC", "[UI] ExtractionMode set to 1 (Light)", "DEBUG")
            EndIf

        ; ------------------------------------------------------------------
        ; Change Description 체크박스 상태 변경 → INI ChangeDescription 즉시 저장
        ;   체크됨    → ChangeDescription=1 (활성화)
        ;   체크 해제 → ChangeDescription=0 (비활성화)
        ; ------------------------------------------------------------------
        Case $Chk_Desc
            If GUICtrlRead($Chk_Desc) = $GUI_CHECKED Then
                IniWrite($sIniPath, "Options", "ChangeDescription", "1")
                _Log("MIC", "[UI] ChangeDescription set to 1", "DEBUG")
            Else
                IniWrite($sIniPath, "Options", "ChangeDescription", "0")
                _Log("MIC", "[UI] ChangeDescription set to 0", "DEBUG")
            EndIf

        ; ------------------------------------------------------------------
        ; Change ProductName 체크박스 상태 변경 → INI ChangeProductName 즉시 저장
        ;   체크됨    → ChangeProductName=1 (활성화)
        ;   체크 해제 → ChangeProductName=0 (비활성화)
        ; ------------------------------------------------------------------
        Case $Chk_ProdName
            If GUICtrlRead($Chk_ProdName) = $GUI_CHECKED Then
                IniWrite($sIniPath, "Options", "ChangeProductName", "1")
                _Log("MIC", "[UI] ChangeProductName set to 1", "DEBUG")
            Else
                IniWrite($sIniPath, "Options", "ChangeProductName", "0")
                _Log("MIC", "[UI] ChangeProductName set to 0", "DEBUG")
            EndIf

        ; ------------------------------------------------------------------
        ; 드래그 앤 드롭 처리
        ; ------------------------------------------------------------------
        Case $GUI_EVENT_DROPPED
            Local $sDropped = @GUI_DragFile
            Local $iDropID  = @GUI_DropId

            If $sDropped <> "" Then
                If $iDropID = $Input_EXE Then
                    If StringRight(StringLower($sDropped), 4) = ".exe" Then
                        GUICtrlSetData($Input_EXE, $sDropped)
                        _Log("MIC", "[Drop] EXE: " & $sDropped, "DEBUG")
                    Else
                        _MsgBoxSquare(48, "Warning", "Only .exe files can be dropped here.")
                        _Log("MIC", "[Drop] Invalid EXE drop: " & $sDropped, "WARN")
                    EndIf
                ElseIf $iDropID = $Input_ICO Then
                    If StringRight(StringLower($sDropped), 4) = ".ico" Then
                        GUICtrlSetData($Input_ICO, $sDropped)
                        _Log("MIC", "[Drop] ICO: " & $sDropped, "DEBUG")
                    Else
                        _MsgBoxSquare(48, "Warning", "Only .ico files can be dropped here.")
                        _Log("MIC", "[Drop] Invalid ICO drop: " & $sDropped, "WARN")
                    EndIf
                EndIf
            EndIf

        ; ------------------------------------------------------------------
        ; 파일 선택 대화상자
        ; ------------------------------------------------------------------
        Case $Btn_FindEXE
            Local $sFileExe = FileOpenDialog("Select EXE File", @ScriptDir, "Executables (*.exe)")
            If Not @error Then
                GUICtrlSetData($Input_EXE, $sFileExe)
                _Log("MIC", "[Select] EXE: " & $sFileExe, "DEBUG")
            EndIf

        Case $Btn_FindICO
            Local $sFileIco = FileOpenDialog("Select ICO File", @ScriptDir, "Icon Files (*.ico)")
            If Not @error Then
                GUICtrlSetData($Input_ICO, $sFileIco)
                _Log("MIC", "[Select] ICO: " & $sFileIco, "DEBUG")
            EndIf

        ; ------------------------------------------------------------------
        ; 기능 1: 아이콘 추출
        ; ------------------------------------------------------------------
        Case $Btn_Extract
            $sExePath = StringStripWS(StringReplace(GUICtrlRead($Input_EXE), @CRLF, ""), 3)

            If $sExePath = "" Or Not FileExists($sExePath) Then
                _MsgBoxSquare(16, "Error", "Please select a target EXE file first.")
                _Log("MIC", "[Error] EXE not found: " & $sExePath, "ERROR")
                ContinueLoop
            EndIf
            If Not FileExists($sRH_Path) Then
                _MsgBoxSquare(16, "Path Error", "ResourceHacker not found at:" & @CRLF & $sRH_Path)
                _Log("MIC", "[Error] RH not found: " & $sRH_Path, "ERROR")
                ContinueLoop
            EndIf

            Local $sTargetDir  = StringLeft($sExePath, StringInStr($sExePath, "\", 0, -1))
            Local $sTargetName = StringMid($sExePath, StringInStr($sExePath, "\", 0, -1) + 1)
            $sTargetName = StringRegExpReplace($sTargetName, "(?i)\.exe$", "")

            Local $iNamingRule     = IniRead($sIniPath, "ExtractConfig", "NamingRule",      "2")
            Local $iExtractMethod  = IniRead($sIniPath, "ExtractConfig", "ExtractMethod",   "2")
            Local $iSaveMethod     = IniRead($sIniPath, "ExtractConfig", "SaveMethod",      "1")
            Local $iExtractionMode = Int(IniRead($sIniPath, "ExtractConfig", "ExtractionMode", "1"))
            Local $iDeepGap        = Int(IniRead($sIniPath, "Advanced",     "DeepModeGap",     "20"))

            _Log("MIC", "[Extract] Target: " & $sExePath)
            _Log("MIC", "[Extract] Mode=" & $iExtractionMode & ", Method=" & $iExtractMethod & ", Naming=" & $iNamingRule, "DEBUG")

            ; 저장 경로 결정
            ; $sSaveBase : ExtractMethod=2(단일)의 경우 파일 전체 경로,
            ;              ExtractMethod=1(전체)의 경우 폴더 경로(\로 끝남)
            Local $sSaveBase = ""
            If $iExtractMethod = "2" Then
                ; 단일 추출
                Local $sSuggestName = ($iNamingRule = "2" ? $sTargetName & ".ico" : "Icon.ico")
                If $iSaveMethod = "1" Then
                    $sSaveBase = $sTargetDir & $sSuggestName
                Else
                    $sSaveBase = FileSaveDialog("Save Icon As", $sTargetDir, "Icon Files (*.ico)", 18, $sSuggestName)
                    If @error Then ContinueLoop
                    If StringRight($sSaveBase, 4) <> ".ico" Then $sSaveBase &= ".ico"
                EndIf
            Else
                ; 전체 추출
                If $iSaveMethod = "1" Then
                    $sSaveBase = $sTargetDir   ; 이미 \ 포함
                Else
                    $sSaveBase = FileSelectFolder("Select Save Folder", $sTargetDir)
                    If @error Then ContinueLoop
                    If StringRight($sSaveBase, 1) <> "\" Then $sSaveBase &= "\"
                EndIf
            EndIf

            ; ==============================================================
            ; ExtractionMode=1  Light 모드: 알려진 3개 ID만 시도 (빠름)
            ; ExtractionMode=2  Deep  모드: -action list 조회 + 브루트포스 폴백
            ; ==============================================================

            If $iExtractionMode = 1 Then
                ; ----------------------------------------------------------
                ; Light 모드
                ; MAINICON / 1 / 101 순으로 최대 3회 시도
                ; $sSaveBase의 역할: ExtractMethod=2 → 파일 경로 / =1 → 폴더 경로(\로 끝남)
                ; ----------------------------------------------------------
                GUICtrlSetData($lbl_Status, "Extracting... (Light)")
                _Log("MIC", "[Extract] Light mode")

                Local $aLightIDs[3] = ["MAINICON", "1", "101"]
                Local $iLightCount  = 0
                Local $bLightDone   = False

                For $i = 0 To 2
                    Local $sLightID   = $aLightIDs[$i]
                    Local $sLightFile = ""

                    If $iExtractMethod = "2" Then
                        $sLightFile = $sSaveBase
                    ElseIf $iNamingRule = "1" Then
                        $sLightFile = $sSaveBase & $sLightID & ".ico"
                    Else
                        $sLightFile = $sSaveBase & $sTargetName & "_" & StringFormat("%03d", $iLightCount + 1) & ".ico"
                    EndIf

                    GUICtrlSetData($lbl_Status, "Trying ID: " & $sLightID & "... (Light)")
                    _Log("MIC", "[Light] Trying ID: " & $sLightID, "DEBUG")

                    RunWait(StringFormat('"%s" -open "%s" -save "%s" -action extract -mask ICONGROUP,%s,', _
                        $sRH_Path, $sExePath, $sLightFile, $sLightID), "", @SW_HIDE)

                    If FileExists($sLightFile) And FileGetSize($sLightFile) > 0 Then
                        $iLightCount += 1
                        _Log("MIC", "[Light] Extracted: " & $sLightFile, "DEBUG")
                        If $iExtractMethod = "2" Then
                            $bLightDone = True
                            ExitLoop
                        EndIf
                    Else
                        If FileExists($sLightFile) Then FileDelete($sLightFile)
                    EndIf
                Next

                If $iExtractMethod = "2" Then
                    If $bLightDone Then
                        GUICtrlSetData($lbl_Status, "Extraction Done!")
                        _MsgBoxSquare(64, "Success", "Icon extracted successfully." & @CRLF & "Saved to: " & $sSaveBase)
                        _Log("MIC", "[Light] Single extract success: " & $sSaveBase)
                    Else
                        GUICtrlSetData($lbl_Status, "Extraction Failed")
                        _MsgBoxSquare(16, "Error", "No icon found." & @CRLF & "Try Deep mode (ExtractionMode=2 in INI).")
                        _Log("MIC", "[Light] Single extract failed.", "ERROR")
                    EndIf
                Else
                    If $iLightCount > 0 Then
                        GUICtrlSetData($lbl_Status, "Extraction Done! (" & $iLightCount & " icons)")
                        _MsgBoxSquare(64, "Success", $iLightCount & " icon(s) extracted." & @CRLF & "Folder: " & $sSaveBase)
                        _Log("MIC", "[Light] " & $iLightCount & " icon(s) extracted.")
                    Else
                        GUICtrlSetData($lbl_Status, "Extraction Failed")
                        _MsgBoxSquare(16, "Error", "No icon found." & @CRLF & "Try Deep mode (ExtractionMode=2 in INI).")
                        _Log("MIC", "[Light] All IDs failed.", "ERROR")
                    EndIf
                EndIf
                GUICtrlSetData($lbl_Status, "Ready")

            Else
                ; ----------------------------------------------------------
                ; Deep 모드
                ; $sSaveBase의 역할: ExtractMethod=2 → 파일 경로 / =1 → 폴더 경로(\로 끝남)
                ;   (Light 모드 전체 추출과 동일한 경로 조립 규칙 적용)
                ; ----------------------------------------------------------
                GUICtrlSetData($lbl_Status, "Scanning IDs... (Deep)")
                _Log("MIC", "[Extract] Deep mode (gap=" & $iDeepGap & ")")

                ; Step 1: -action list 로 ID 조회
                Local $aFoundIDs   = _RH_GetIconGroupIDs($sRH_Path, $sExePath)
                Local $iTotalFound = $aFoundIDs[0]

                ; Step 2: 조회 실패 시 브루트포스 폴백
                If $iTotalFound = 0 Then
                    _Log("MIC", "[Deep] List scan returned 0. Switching to brute-force.", "WARN")
                    GUICtrlSetData($lbl_Status, "Scanning IDs... (BruteForce)")
                    $aFoundIDs   = _RH_BruteForceIDs($sRH_Path, $sExePath, $iDeepGap)
                    $iTotalFound = $aFoundIDs[0]
                EndIf

                ; Step 3: 조회된 ID로 추출
                If $iTotalFound = 0 Then
                    GUICtrlSetData($lbl_Status, "Extraction Failed")
                    _MsgBoxSquare(16, "Error", "No icon found." & @CRLF & "The file might be packed or protected.")
                    _Log("MIC", "[Deep] No IDs found.", "ERROR")
                    GUICtrlSetData($lbl_Status, "Ready")
                    ContinueLoop
                EndIf

                If $iExtractMethod = "2" Then
                    ; 단일 추출: 첫 번째 성공 ID 사용
                    Local $bDeepSingle = False
                    For $i = 1 To $iTotalFound
                        Local $sDeepID = $aFoundIDs[$i]
                        GUICtrlSetData($lbl_Status, "Extracting " & $i & "/" & $iTotalFound & " (ID: " & $sDeepID & ")")
                        _Log("MIC", "[Deep] Trying ID: " & $sDeepID, "DEBUG")

                        RunWait(StringFormat('"%s" -open "%s" -save "%s" -action extract -mask ICONGROUP,%s,', _
                            $sRH_Path, $sExePath, $sSaveBase, $sDeepID), "", @SW_HIDE)

                        If FileExists($sSaveBase) And FileGetSize($sSaveBase) > 0 Then
                            $bDeepSingle = True
                            _Log("MIC", "[Deep] Single success: ID=" & $sDeepID)
                            ExitLoop
                        EndIf
                    Next

                    If $bDeepSingle Then
                        GUICtrlSetData($lbl_Status, "Extraction Done!")
                        _MsgBoxSquare(64, "Success", "Icon extracted successfully." & @CRLF & "Saved to: " & $sSaveBase)
                        _Log("MIC", "[Deep] Saved: " & $sSaveBase)
                    Else
                        GUICtrlSetData($lbl_Status, "Extraction Failed")
                        _MsgBoxSquare(16, "Error", "No valid icon found." & @CRLF & "The file might be packed or protected.")
                        _Log("MIC", "[Deep] Single extract failed.", "ERROR")
                    EndIf

                Else
                    ; 전체 추출: 조회된 모든 ID 처리
                    ; 경로 조립 규칙은 Light 모드 전체 추출과 동일합니다.
                    Local $iDeepCount = 0
                    For $m = 1 To $iTotalFound
                        Local $sDeepMultiID = $aFoundIDs[$m]
                        Local $sDeepFile    = ""

                        If $iNamingRule = "1" Then
                            $sDeepFile = $sSaveBase & $sDeepMultiID & ".ico"
                        Else
                            $sDeepFile = $sSaveBase & $sTargetName & "_" & StringFormat("%03d", $iDeepCount + 1) & ".ico"
                        EndIf

                        GUICtrlSetData($lbl_Status, "Extracting " & $m & "/" & $iTotalFound & " (ID: " & $sDeepMultiID & ")")
                        _Log("MIC", "[Deep] Extracting ID: " & $sDeepMultiID, "DEBUG")

                        RunWait(StringFormat('"%s" -open "%s" -save "%s" -action extract -mask ICONGROUP,%s,', _
                            $sRH_Path, $sExePath, $sDeepFile, $sDeepMultiID), "", @SW_HIDE)

                        If FileExists($sDeepFile) And FileGetSize($sDeepFile) > 0 Then
                            $iDeepCount += 1
                            _Log("MIC", "[Deep] Extracted: " & $sDeepFile, "DEBUG")
                        Else
                            If FileExists($sDeepFile) Then FileDelete($sDeepFile)
                            _Log("MIC", "[Deep] Failed for ID: " & $sDeepMultiID, "WARN")
                        EndIf
                    Next

                    If $iDeepCount > 0 Then
                        GUICtrlSetData($lbl_Status, "Extraction Done! (" & $iDeepCount & " icons)")
                        _MsgBoxSquare(64, "Success", $iDeepCount & " icon(s) extracted." & @CRLF & "Folder: " & $sSaveBase)
                        _Log("MIC", "[Deep] " & $iDeepCount & " icon(s) extracted to: " & $sSaveBase)
                    Else
                        GUICtrlSetData($lbl_Status, "Extraction Failed")
                        _MsgBoxSquare(16, "Error", "Failed to extract any icon." & @CRLF & "The file might be packed or protected.")
                        _Log("MIC", "[Deep] All extractions failed.", "ERROR")
                    EndIf
                EndIf
                GUICtrlSetData($lbl_Status, "Ready")
            EndIf

        ; ------------------------------------------------------------------
        ; 기능 2: 아이콘 변경
        ; ------------------------------------------------------------------
        Case $Btn_Run
            $sExePath = StringStripWS(StringReplace(GUICtrlRead($Input_EXE), @CRLF, ""), 3)
            $sIcoPath = StringStripWS(StringReplace(GUICtrlRead($Input_ICO), @CRLF, ""), 3)

            Local $iChangeDesc = Int(IniRead($sIniPath, "Options", "ChangeDescription", "0"))
            Local $iChangeProd = Int(IniRead($sIniPath, "Options", "ChangeProductName", "0"))

            ; EXE 유효성 검사
            If $sExePath = "" Or Not FileExists($sExePath) Then
                _MsgBoxSquare(16, "Error", "EXE file not found.")
                _Log("MIC", "[Error] EXE not found: " & $sExePath, "ERROR")
                ContinueLoop
            EndIf

            ; ICO 없고 Description도 ProductName도 꺼져 있으면 할 일 없음
            Local $bDoIcon = ($sIcoPath <> "" And FileExists($sIcoPath))
            Local $bDoDesc = ($iChangeDesc = 1 And GUICtrlRead($Chk_Desc) = $GUI_CHECKED)
            Local $bDoProd = ($iChangeProd = 1 And GUICtrlRead($Chk_ProdName) = $GUI_CHECKED)

            If Not $bDoIcon And Not $bDoDesc And Not $bDoProd Then
                _MsgBoxSquare(48, "Warning", "No ICO file specified and both Change Description and Change ProductName are disabled." & @CRLF & "Nothing to do.")
                _Log("MIC", "[Warn] Nothing to do — no ICO, ChangeDescription=0, ChangeProductName=0.", "WARN")
                ContinueLoop
            EndIf

            ; ICO 교체가 필요한데 RH 없으면 에러
            If $bDoIcon And Not FileExists($sRH_Path) Then
                _MsgBoxSquare(16, "Path Error", "ResourceHacker not found at:" & @CRLF & $sRH_Path)
                _Log("MIC", "[Error] RH not found: " & $sRH_Path, "ERROR")
                ContinueLoop
            EndIf

            _Log("MIC", "[Change] Target: " & $sExePath)
            If $bDoIcon Then _Log("MIC", "[Change] Icon: " & $sIcoPath)
            If $bDoDesc Then _Log("MIC", "[Change] ChangeDescription=1")
            If $bDoProd Then _Log("MIC", "[Change] ChangeProductName=1")

            ; 백업
            Local $iBackup = Int(IniRead($sIniPath, "Options", "BackupBeforeChange", "1"))
            If $iBackup = 1 Then
                Local $sBackupPath = $sExePath & ".bak"
                If FileCopy($sExePath, $sBackupPath, 1) Then
                    _Log("MIC", "[Change] Backup created: " & $sBackupPath)
                Else
                    GUICtrlSetData($lbl_Status, "Backup Failed")
                    _MsgBoxSquare(16, "Backup Error", "Failed to create backup file." & @CRLF & $sBackupPath)
                    _Log("MIC", "[Error] Backup failed: " & $sBackupPath, "ERROR")
                    ContinueLoop
                EndIf
            EndIf

            ; ------------------------------------------------------------------
            ; Step A: 아이콘 교체 (ICO가 지정된 경우에만)
            ; ------------------------------------------------------------------
            Local $bIconOK = False
            If $bDoIcon Then
                GUICtrlSetData($lbl_Status, "Processing (Change Icon)...")
                Local $sCmdChange = StringFormat('"%s" -open "%s" -save "%s" -action addoverwrite -res "%s" -mask ICONGROUP,MAINICON,', _
                    $sRH_Path, $sExePath, $sExePath, $sIcoPath)
                Local $iRet = RunWait($sCmdChange, "", @SW_HIDE)
                If $iRet = 0 Then
                    $bIconOK = True
                    _Log("MIC", "[Change] Icon replaced successfully.")
                Else
                    _Log("MIC", "[Error] Icon change failed. RetCode: " & $iRet, "ERROR")
                EndIf
            EndIf

            ; ------------------------------------------------------------------
            ; Step B: FileDescription 패치 (ChangeDescription=1 인 경우에만)
            ; 아이콘 교체 성공/실패와 무관하게 독립 실행
            ; ------------------------------------------------------------------
            Local $bDescOK = False
            If $bDoDesc Then
                Local $sNewDesc = StringRegExpReplace($sExePath, "^.*\\", "")
                $sNewDesc = StringRegExpReplace($sNewDesc, "(?i)\.exe$", "")

                GUICtrlSetData($lbl_Status, "Updating Description...")
                _Log("MIC", "[Desc] NewDesc=" & $sNewDesc)

                $bDescOK = _PatchFileDescription($sExePath, $sNewDesc)
            EndIf

            ; ------------------------------------------------------------------
            ; Step C: ProductName 패치 (ChangeProductName=1 인 경우에만)
            ; ------------------------------------------------------------------
            Local $bProdOK = False
            If $bDoProd Then
                Local $sNewProd = StringRegExpReplace($sExePath, "^.*\\", "")
                $sNewProd = StringRegExpReplace($sNewProd, "(?i)\.exe$", "")

                GUICtrlSetData($lbl_Status, "Updating ProductName...")
                _Log("MIC", "[Prod] NewProd=" & $sNewProd)

                $bProdOK = _PatchProductName($sExePath, $sNewProd)
            EndIf

            ; ------------------------------------------------------------------
            ; 결과 메시지
            ;
            ; 형식:
            ;   [Change Success]
            ;   - Icon
            ;   - File description
            ;   - Product name
            ;   [Change Failed]
            ;   - Icon
            ;   - File description
            ;   - Product name
            ;
            ; 해당 항목만 표시. 모두 성공이면 [Change Failed] 생략, 반대도 동일.
            ; ------------------------------------------------------------------
            Local $sSuccessList = ""
            Local $sFailedList  = ""

            If $bDoIcon Then
                If $bIconOK Then
                    $sSuccessList &= "- Icon" & @CRLF
                Else
                    $sFailedList  &= "- Icon" & @CRLF
                EndIf
            EndIf
            If $bDoDesc Then
                If $bDescOK Then
                    $sSuccessList &= "- File description" & @CRLF
                Else
                    $sFailedList  &= "- File description" & @CRLF
                EndIf
            EndIf
            If $bDoProd Then
                If $bProdOK Then
                    $sSuccessList &= "- Product name" & @CRLF
                Else
                    $sFailedList  &= "- Product name" & @CRLF
                EndIf
            EndIf

            ; 성공/실패 여부 집계
            Local $bAnySuccess = ($sSuccessList <> "")
            Local $bAnyFailed  = ($sFailedList  <> "")

            ; 결과 메시지 조립
            Local $sMsgResult = ""
            If $bAnySuccess Then
                $sMsgResult &= "[Change Success]" & @CRLF & $sSuccessList
            EndIf
            If $bAnyFailed Then
                If $sMsgResult <> "" Then $sMsgResult &= @CRLF
                $sMsgResult &= "[Change Failed]" & @CRLF & $sFailedList
            EndIf
            $sMsgResult = StringStripWS($sMsgResult, 2)  ; 후행 공백/줄바꿈 제거

            ; Status 레이블 및 메시지 박스 표시
            If $bAnySuccess And Not $bAnyFailed Then
                GUICtrlSetData($lbl_Status, "Done!")
                _MsgBoxSquare(64, "Success", $sMsgResult)
                _Log("MIC", "[Change] All succeeded.")
            ElseIf $bAnySuccess And $bAnyFailed Then
                GUICtrlSetData($lbl_Status, "Partial Success")
                _MsgBoxSquare(48, "Partial Success", $sMsgResult)
                _Log("MIC", "[Change] Partial success.", "WARN")
            Else
                GUICtrlSetData($lbl_Status, "Failed")
                _MsgBoxSquare(16, "Error", $sMsgResult)
                _Log("MIC", "[Change] All failed.", "ERROR")
            EndIf

            GUICtrlSetData($lbl_Status, "Ready")

    EndSwitch
WEnd

; =================================================================================================
; [Desc] Win32 API 직접 패치 — BeginUpdateResource / UpdateResource / EndUpdateResource
; -------------------------------------------------------------------------------------------------
; RH는 -res에 .rc 텍스트를 받지 못합니다(-res는 바이너리 전용).
; 따라서 RH를 완전히 배제하고 Win32 API로 VERSIONINFO 바이너리를 직접 읽어
; FileDescription 필드만 UTF-16LE in-place 패치합니다.
;
; 동작 순서:
;   Step 1: LoadLibraryEx(LOAD_LIBRARY_AS_DATAFILE)로 EXE를 읽기 전용 로드
;   Step 2: FindResource(RT_VERSION=16, ID=1) + LoadResource + LockResource 로 바이너리 획득
;   Step 3: 바이너리를 AutoIt 이진 문자열로 복사
;   Step 4: FreeLibrary
;   Step 5: UTF-16LE 바이너리 내에서 FileDescription\0 마커를 찾아 뒤따르는 값 in-place 패치
;   Step 6: BeginUpdateResource → UpdateResource(RT_VERSION,1) → EndUpdateResource
; =================================================================================================
Func _PatchFileDescription($sExePath, $sNewDesc)
    ; -----------------------------------------------------------------------
    ; Step 1~4: VERSIONINFO 바이너리 획득
    ; -----------------------------------------------------------------------
    Local Const $LOAD_LIBRARY_AS_DATAFILE = 0x02
    Local Const $RT_VERSION               = 16

    Local $hLib = DllCall("kernel32.dll", "handle", "LoadLibraryExW", _
        "wstr", $sExePath, "handle", 0, "dword", $LOAD_LIBRARY_AS_DATAFILE)
    If @error Or $hLib[0] = 0 Then
        _Log("MIC", "[Desc] LoadLibraryEx failed (err=" & @error & ")", "WARN")
        Return False
    EndIf
    $hLib = $hLib[0]

    Local $hResInfo = DllCall("kernel32.dll", "handle", "FindResourceW", _
        "handle", $hLib, "int", 1, "int", $RT_VERSION)
    If @error Or $hResInfo[0] = 0 Then
        _Log("MIC", "[Desc] FindResource failed — no VERSIONINFO.", "WARN")
        DllCall("kernel32.dll", "bool", "FreeLibrary", "handle", $hLib)
        Return False
    EndIf
    $hResInfo = $hResInfo[0]

    Local $iSize = DllCall("kernel32.dll", "dword", "SizeofResource", _
        "handle", $hLib, "handle", $hResInfo)
    $iSize = $iSize[0]
    _Log("MIC", "[Desc] Step1 VERSIONINFO size=" & $iSize, "DEBUG")

    If $iSize = 0 Then
        _Log("MIC", "[Desc] SizeofResource=0.", "WARN")
        DllCall("kernel32.dll", "bool", "FreeLibrary", "handle", $hLib)
        Return False
    EndIf

    Local $hResData = DllCall("kernel32.dll", "handle", "LoadResource", _
        "handle", $hLib, "handle", $hResInfo)
    $hResData = $hResData[0]

    Local $pData = DllCall("kernel32.dll", "ptr", "LockResource", "handle", $hResData)
    $pData = $pData[0]

    ; 바이너리를 AutoIt 구조체로 복사
    Local $tBuf = DllStructCreate("byte[" & $iSize & "]")
    DllCall("kernel32.dll", "none", "RtlMoveMemory", _
        "ptr", DllStructGetPtr($tBuf), "ptr", $pData, "dword_ptr", $iSize)

    DllCall("kernel32.dll", "bool", "FreeLibrary", "handle", $hLib)

    ; -----------------------------------------------------------------------
    ; Step 5: UTF-16LE 바이너리 내에서 FileDescription\0 마커를 찾아 값 패치
    ;
    ; VERSIONINFO StringTable 구조 (UTF-16LE):
    ;   키 문자열(UTF-16LE, NUL종결) → 패딩(4바이트 정렬) → 값 문자열(UTF-16LE, NUL종결)
    ;
    ; 마커: "FileDescription" + 0x0000 (UTF-16LE, 총 34 bytes)
    ;   F=46 00  i=69 00  l=6C 00  e=65 00  D=44 00  e=65 00  s=73 00  c=63 00
    ;   r=72 00  i=69 00  p=70 00  t=74 00  i=69 00  o=6F 00  n=6E 00  NUL=00 00
    ; -----------------------------------------------------------------------
    Local $sMarker = Chr(0x46) & Chr(0) & Chr(0x69) & Chr(0) & Chr(0x6C) & Chr(0) & _
                     Chr(0x65) & Chr(0) & Chr(0x44) & Chr(0) & Chr(0x65) & Chr(0) & _
                     Chr(0x73) & Chr(0) & Chr(0x63) & Chr(0) & Chr(0x72) & Chr(0) & _
                     Chr(0x69) & Chr(0) & Chr(0x70) & Chr(0) & Chr(0x74) & Chr(0) & _
                     Chr(0x69) & Chr(0) & Chr(0x6F) & Chr(0) & Chr(0x6E) & Chr(0) & _
                     Chr(0) & Chr(0)   ; NUL terminator of key

    ; 구조체를 문자열로 변환하여 검색
    Local $sRaw = ""
    For $bi = 1 To $iSize
        $sRaw &= Chr(DllStructGetData($tBuf, 1, $bi))
    Next

    Local $iMarkerPos = StringInStr($sRaw, $sMarker, 2)  ; 2 = 이진 검색
    If $iMarkerPos = 0 Then
        _Log("MIC", "[Desc] FileDescription marker not found in binary.", "WARN")
        Return False
    EndIf
    _Log("MIC", "[Desc] Step5 marker found at byte offset=" & ($iMarkerPos - 1), "DEBUG")

    ; 마커 끝 다음 위치: 4바이트 정렬(DWORD align) 후 값 시작
    ; 키 끝 바이트 오프셋(0-based): $iMarkerPos - 1 + 32 - 1 = $iMarkerPos + 30
    Local $iKeyEnd    = $iMarkerPos - 1 + StringLen($sMarker) ; 0-based 다음 바이트
    ; DWORD(4바이트) 정렬
    Local $iValStart  = $iKeyEnd + (4 - Mod($iKeyEnd, 4))
    If Mod($iKeyEnd, 4) = 0 Then $iValStart = $iKeyEnd

    _Log("MIC", "[Desc] Step5 value starts at byte=" & $iValStart, "DEBUG")

    ; 기존 값 길이 측정(UTF-16LE NUL 탐색)
    Local $iOldValLen = 0
    Local $iScan = $iValStart
    While $iScan + 1 < $iSize
        If Asc(StringMid($sRaw, $iScan + 1, 1)) = 0 And Asc(StringMid($sRaw, $iScan + 2, 1)) = 0 Then
            ExitLoop
        EndIf
        $iScan += 2
        $iOldValLen += 1  ; UTF-16LE 문자 단위
    WEnd
    _Log("MIC", "[Desc] Step5 old value char-count=" & $iOldValLen & " new='" & $sNewDesc & "'", "DEBUG")

    ; 새 값을 UTF-16LE로 인코딩하여 구조체에 덮어씀
    ; 길이가 다를 경우: 짧은 쪽은 나머지를 0x00 패딩, 긴 쪽은 잘라냄(기존 값 영역만큼)
    Local $iMaxChars = $iOldValLen
    Local $sNewTrunc = StringLeft($sNewDesc, $iMaxChars)
    Local $iWriteChars = StringLen($sNewTrunc)

    For $ci = 1 To $iMaxChars
        Local $iByte1 = 0
        Local $iByte2 = 0
        If $ci <= $iWriteChars Then
            $iByte1 = Asc(StringMid($sNewTrunc, $ci, 1))
            ; ASCII 범위: 하위 바이트만 사용, 상위 바이트 0x00
        EndIf
        DllStructSetData($tBuf, 1, $iByte1, $iValStart + ($ci - 1) * 2 + 1)
        DllStructSetData($tBuf, 1, $iByte2, $iValStart + ($ci - 1) * 2 + 2)
    Next
    ; NUL terminator (이미 0이지만 명시적으로 기록)
    DllStructSetData($tBuf, 1, 0, $iValStart + $iMaxChars * 2 + 1)
    DllStructSetData($tBuf, 1, 0, $iValStart + $iMaxChars * 2 + 2)

    ; -----------------------------------------------------------------------
    ; Step 6: BeginUpdateResource → UpdateResource → EndUpdateResource
    ; -----------------------------------------------------------------------
    Local $hUpdate = DllCall("kernel32.dll", "handle", "BeginUpdateResourceW", _
        "wstr", $sExePath, "bool", False)
    If @error Or $hUpdate[0] = 0 Then
        Local $iErr = DllCall("kernel32.dll", "dword", "GetLastError")[0]
        _Log("MIC", "[Desc] BeginUpdateResource failed (LastErr=" & $iErr & ")", "WARN")
        Return False
    EndIf
    $hUpdate = $hUpdate[0]
    _Log("MIC", "[Desc] Step6 BeginUpdateResource OK", "DEBUG")

    Local $bUpd = DllCall("kernel32.dll", "bool", "UpdateResourceW", _
        "handle", $hUpdate, _
        "int",    $RT_VERSION, _
        "int",    1, _
        "word",   0x0409, _
        "ptr",    DllStructGetPtr($tBuf), _
        "dword",  $iSize)
    If @error Or $bUpd[0] = 0 Then
        Local $iErr2 = DllCall("kernel32.dll", "dword", "GetLastError")[0]
        _Log("MIC", "[Desc] UpdateResource failed (LastErr=" & $iErr2 & ")", "WARN")
        DllCall("kernel32.dll", "bool", "EndUpdateResourceW", "handle", $hUpdate, "bool", True)
        Return False
    EndIf
    _Log("MIC", "[Desc] Step6 UpdateResource OK", "DEBUG")

    Local $bEnd = DllCall("kernel32.dll", "bool", "EndUpdateResourceW", _
        "handle", $hUpdate, "bool", False)
    If @error Or $bEnd[0] = 0 Then
        Local $iErr3 = DllCall("kernel32.dll", "dword", "GetLastError")[0]
        _Log("MIC", "[Desc] EndUpdateResource failed (LastErr=" & $iErr3 & ")", "WARN")
        Return False
    EndIf

    _Log("MIC", "[Desc] Description updated successfully.")
    Return True
EndFunc

; =================================================================================================
; [Prod] Win32 API 직접 패치 — ProductName 필드
; -------------------------------------------------------------------------------------------------
; _PatchFileDescription 과 동일한 구조.
; UTF-16LE 바이너리 내에서 "ProductName\0" 마커를 탐색한 뒤
; 뒤따르는 값 영역을 새 이름으로 in-place 덮어씁니다.
;
; 마커: "ProductName" + 0x0000 (UTF-16LE, 총 24 bytes)
;   P=50 00  r=72 00  o=6F 00  d=64 00  u=75 00  c=63 00  t=74 00
;   N=4E 00  a=61 00  m=6D 00  e=65 00  NUL=00 00
; =================================================================================================
Func _PatchProductName($sExePath, $sNewProd)
    ; -----------------------------------------------------------------------
    ; Step 1~4: VERSIONINFO 바이너리 획득 (_PatchFileDescription 과 동일)
    ; -----------------------------------------------------------------------
    Local Const $LOAD_LIBRARY_AS_DATAFILE = 0x02
    Local Const $RT_VERSION               = 16

    Local $hLib = DllCall("kernel32.dll", "handle", "LoadLibraryExW", _
        "wstr", $sExePath, "handle", 0, "dword", $LOAD_LIBRARY_AS_DATAFILE)
    If @error Or $hLib[0] = 0 Then
        _Log("MIC", "[Prod] LoadLibraryEx failed (err=" & @error & ")", "WARN")
        Return False
    EndIf
    $hLib = $hLib[0]

    Local $hResInfo = DllCall("kernel32.dll", "handle", "FindResourceW", _
        "handle", $hLib, "int", 1, "int", $RT_VERSION)
    If @error Or $hResInfo[0] = 0 Then
        _Log("MIC", "[Prod] FindResource failed — no VERSIONINFO.", "WARN")
        DllCall("kernel32.dll", "bool", "FreeLibrary", "handle", $hLib)
        Return False
    EndIf
    $hResInfo = $hResInfo[0]

    Local $iSize = DllCall("kernel32.dll", "dword", "SizeofResource", _
        "handle", $hLib, "handle", $hResInfo)
    $iSize = $iSize[0]
    _Log("MIC", "[Prod] Step1 VERSIONINFO size=" & $iSize, "DEBUG")

    If $iSize = 0 Then
        _Log("MIC", "[Prod] SizeofResource=0.", "WARN")
        DllCall("kernel32.dll", "bool", "FreeLibrary", "handle", $hLib)
        Return False
    EndIf

    Local $hResData = DllCall("kernel32.dll", "handle", "LoadResource", _
        "handle", $hLib, "handle", $hResInfo)
    $hResData = $hResData[0]

    Local $pData = DllCall("kernel32.dll", "ptr", "LockResource", "handle", $hResData)
    $pData = $pData[0]

    Local $tBuf = DllStructCreate("byte[" & $iSize & "]")
    DllCall("kernel32.dll", "none", "RtlMoveMemory", _
        "ptr", DllStructGetPtr($tBuf), "ptr", $pData, "dword_ptr", $iSize)

    DllCall("kernel32.dll", "bool", "FreeLibrary", "handle", $hLib)

    ; -----------------------------------------------------------------------
    ; Step 5: UTF-16LE 바이너리 내에서 ProductName\0 마커를 찾아 값 패치
    ;
    ; 마커: "ProductName" + 0x0000 (UTF-16LE, 총 24 bytes)
    ;   P=50 00  r=72 00  o=6F 00  d=64 00  u=75 00  c=63 00  t=74 00
    ;   N=4E 00  a=61 00  m=6D 00  e=65 00  NUL=00 00
    ; -----------------------------------------------------------------------
    Local $sMarker = Chr(0x50) & Chr(0) & Chr(0x72) & Chr(0) & Chr(0x6F) & Chr(0) & _
                     Chr(0x64) & Chr(0) & Chr(0x75) & Chr(0) & Chr(0x63) & Chr(0) & _
                     Chr(0x74) & Chr(0) & Chr(0x4E) & Chr(0) & Chr(0x61) & Chr(0) & _
                     Chr(0x6D) & Chr(0) & Chr(0x65) & Chr(0) & _
                     Chr(0) & Chr(0)   ; NUL terminator of key

    Local $sRaw = ""
    For $bi = 1 To $iSize
        $sRaw &= Chr(DllStructGetData($tBuf, 1, $bi))
    Next

    Local $iMarkerPos = StringInStr($sRaw, $sMarker, 2)
    If $iMarkerPos = 0 Then
        _Log("MIC", "[Prod] ProductName marker not found in binary.", "WARN")
        Return False
    EndIf
    _Log("MIC", "[Prod] Step5 marker found at byte offset=" & ($iMarkerPos - 1), "DEBUG")

    Local $iKeyEnd   = $iMarkerPos - 1 + StringLen($sMarker)
    Local $iValStart = $iKeyEnd + (4 - Mod($iKeyEnd, 4))
    If Mod($iKeyEnd, 4) = 0 Then $iValStart = $iKeyEnd

    _Log("MIC", "[Prod] Step5 value starts at byte=" & $iValStart, "DEBUG")

    Local $iOldValLen = 0
    Local $iScan = $iValStart
    While $iScan + 1 < $iSize
        If Asc(StringMid($sRaw, $iScan + 1, 1)) = 0 And Asc(StringMid($sRaw, $iScan + 2, 1)) = 0 Then
            ExitLoop
        EndIf
        $iScan += 2
        $iOldValLen += 1
    WEnd
    _Log("MIC", "[Prod] Step5 old value char-count=" & $iOldValLen & " new='" & $sNewProd & "'", "DEBUG")

    Local $iMaxChars  = $iOldValLen
    Local $sNewTrunc  = StringLeft($sNewProd, $iMaxChars)
    Local $iWriteChars = StringLen($sNewTrunc)

    For $ci = 1 To $iMaxChars
        Local $iByte1 = 0
        Local $iByte2 = 0
        If $ci <= $iWriteChars Then
            $iByte1 = Asc(StringMid($sNewTrunc, $ci, 1))
        EndIf
        DllStructSetData($tBuf, 1, $iByte1, $iValStart + ($ci - 1) * 2 + 1)
        DllStructSetData($tBuf, 1, $iByte2, $iValStart + ($ci - 1) * 2 + 2)
    Next
    DllStructSetData($tBuf, 1, 0, $iValStart + $iMaxChars * 2 + 1)
    DllStructSetData($tBuf, 1, 0, $iValStart + $iMaxChars * 2 + 2)

    ; -----------------------------------------------------------------------
    ; Step 6: BeginUpdateResource → UpdateResource → EndUpdateResource
    ; -----------------------------------------------------------------------
    Local $hUpdate = DllCall("kernel32.dll", "handle", "BeginUpdateResourceW", _
        "wstr", $sExePath, "bool", False)
    If @error Or $hUpdate[0] = 0 Then
        Local $iErr = DllCall("kernel32.dll", "dword", "GetLastError")[0]
        _Log("MIC", "[Prod] BeginUpdateResource failed (LastErr=" & $iErr & ")", "WARN")
        Return False
    EndIf
    $hUpdate = $hUpdate[0]
    _Log("MIC", "[Prod] Step6 BeginUpdateResource OK", "DEBUG")

    Local $bUpd = DllCall("kernel32.dll", "bool", "UpdateResourceW", _
        "handle", $hUpdate, _
        "int",    $RT_VERSION, _
        "int",    1, _
        "word",   0x0409, _
        "ptr",    DllStructGetPtr($tBuf), _
        "dword",  $iSize)
    If @error Or $bUpd[0] = 0 Then
        Local $iErr2 = DllCall("kernel32.dll", "dword", "GetLastError")[0]
        _Log("MIC", "[Prod] UpdateResource failed (LastErr=" & $iErr2 & ")", "WARN")
        DllCall("kernel32.dll", "bool", "EndUpdateResourceW", "handle", $hUpdate, "bool", True)
        Return False
    EndIf
    _Log("MIC", "[Prod] Step6 UpdateResource OK", "DEBUG")

    Local $bEnd = DllCall("kernel32.dll", "bool", "EndUpdateResourceW", _
        "handle", $hUpdate, "bool", False)
    If @error Or $bEnd[0] = 0 Then
        Local $iErr3 = DllCall("kernel32.dll", "dword", "GetLastError")[0]
        _Log("MIC", "[Prod] EndUpdateResource failed (LastErr=" & $iErr3 & ")", "WARN")
        Return False
    EndIf

    _Log("MIC", "[Prod] ProductName updated successfully.")
    Return True
EndFunc
