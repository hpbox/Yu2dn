#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\icons\FormsIcon.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         myName

 Script Function:
	Downloader utility for yu2dn

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

#include <ButtonConstants.au3>
#include <IE.au3>
#include <File.au3>
#include <Date.au3>
#include <WinAPIFiles.au3>
#include <ComboConstants.au3>
#include <InetConstants.au3>
#include <MsgBoxConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include "_URLCodec.au3"

Opt("GUIOnEventMode", 1)
Opt("MustDeclareVars", 1)
Opt("GUICloseOnESC", 0)

;global variables
Global $Form1
Global $dltemp
Global $file_handle

;main function
_Main()
While 1
	Sleep(100)
WEnd

;close
Func _Close()
	MsgBox(8208, "訊息", "使用者終止操作")
	;FileDelete($dltemp)
	InetClose($file_handle)
	Exit
EndFunc

Func _Close2()
	;MsgBox(8208, "訊息", "使用者終止操作")
	;FileDelete($dltemp)
	InetClose($file_handle)
	Exit
EndFunc

;main window
Func _Main()
	Local $F1Prog1
	Local $F1Label1
	Local $F1Label2
	Local $F1Label3
	Local $F1Label4
	Local $F1Button1
	Local $F1Button2

	Local $dltemp_file

	Local $video_url
	Local $audio_url
	Local $mux_option
	Local $dlpath
	Local $title
	Local $type
	Local $filename_woext
	Local $filename
	Local $audiofilename

	Local $dummy

	Local $dl_count

	;$dltemp = "1234.tmp"


	If $CmdLine[0] > 0 Then
		$dltemp= $CmdLine[1]
	Else
		ConsoleWrite("[error] No file to download. Exiting." & @CRLF)
		Exit
	EndIf


	$dltemp_file = FileOpen($dltemp)
	$video_url = FileReadLine($dltemp_file)
	$mux_option = FileReadLine($dltemp_file)
	$dummy = FileReadLine($dltemp_file)
	$dlpath = FileReadLine($dltemp_file)
	$title = FileReadLine($dltemp_file)
	$type = FileReadLine($dltemp_file)


	ConsoleWrite("[debug] Video url: " & $video_url & @CRLF)
	ConsoleWrite("[debug] Mux option: " & $mux_option & @CRLF)
	ConsoleWrite("[debug] Download Path: " & $dlpath & @CRLF)
	ConsoleWrite("[debug] Title: " & $title & @CRLF)
	ConsoleWrite("[debug] File type: " & $type & @CRLF)
	If StringInStr($type, "mp4") <> 0 Then
		$type = "mp4"
	ElseIf StringInStr($type, "webm") <> 0 Then
		$type = "ogv"
	EndIf

	If StringInStr($mux_option, "1") <> 0 Then
		$audio_url = FileReadLine($dltemp_file)
		$dl_count = 2
	Else
		$dl_count = 1
	EndIf

	FileClose($dltemp_file)
	FileDelete($dltemp)

	$filename = $title & "." & $type
	$audiofilename = $title & "." & "m4a"
	$filename = StringRegExpReplace($filename, '[ /:*?"<>|\\]', '_')
	$audiofilename = StringRegExpReplace($audiofilename, '[ /:*?"<>|\\]', '_')
	$filename_woext = StringRegExpReplace($title, '[ /:*?"<>|\\]', '_')
	ConsoleWrite("[debug] Filename: " & $filename & @CRLF)

	$Form1 = GUICreate("影片下載", 400, 150, 271, 380)

	$F1Prog1 = GUICtrlCreateProgress(16, 80, 368, 20)
	$F1Label1 = GUICtrlCreateLabel("標題: ", 16, 16, 40, 18)
	$F1Label2 = GUICtrlCreateLabel("狀態: ", 16, 55, 40, 18)
	$F1Label3 = GUICtrlCreateLabel("", 56, 16, 328, 40)
	$F1Label4 = GUICtrlCreateLabel("", 56, 55, 328, 18)
	$F1Button1 = GUICtrlCreateButton("取消", 311, 110, 73, 25)
	$F1Button2 = GUICtrlCreateButton("確定", 228, 110, 73, 25)


	;gui events
	GUISetOnEvent($GUI_EVENT_CLOSE, "_Close")
	GUICtrlSetOnEvent($F1Button1, "_Close")
	GUICtrlSetOnEvent($F1Button2, "_Close2")

	;show Form1
	GUISetState(@SW_SHOW)

	GUICtrlSetData($F1Label3, $filename)
	GUICtrlSetState($F1Button2, 128)



	Local $dl_info


	$file_handle = InetGet($video_url, $dlpath & "\" & $filename, 1, 1)
	While 1
		$dl_info = InetGetInfo($file_handle)
		If $dl_info <> "" Then
			If $dl_info[0] = 0 Then
				GUICtrlSetData($F1Label4, "0 % [" & $dl_info[0] & " bytes/ " & $dl_info[1] & " bytes]")
				GUICtrlSetData($F1Prog1, 0)
			Else
				GUICtrlSetData($F1Label4, Int(100*Round($dl_info[0]/$dl_info[1], 2)) & " % [" & $dl_info[0] & " bytes/ " & $dl_info[1] & " bytes]")
				GUICtrlSetData($F1Prog1, Int(100*Round($dl_info[0]/$dl_info[1], 2)))
			EndIf
			If $dl_info[3] = True Then
				GUICtrlSetData($F1Label4, "100 % [" & $dl_info[0] & " bytes/ 下載完成]")
				$dl_count = $dl_count - 1
				ExitLoop
			EndIf
		EndIf
		Sleep(500)
	WEnd
	InetClose($file_handle)

	If $mux_option = "1" Then
		$file_handle = InetGet($audio_url, $dlpath & "\" & $audiofilename, 1, 1)
		While 1
			$dl_info = InetGetInfo($file_handle)
			If $dl_info <> "" Then
				If $dl_info[0] = 0 Then
					GUICtrlSetData($F1Label4, "下載音訊檔案... 0 % [" & $dl_info[0] & " bytes/ " & $dl_info[1] & " bytes]")
					GUICtrlSetData($F1Prog1, 0)
				Else
					GUICtrlSetData($F1Label4, "下載音訊檔案... " & Int(100*Round($dl_info[0]/$dl_info[1], 2)) & " % [" & $dl_info[0] & " bytes/ " & $dl_info[1] & " bytes]")
					GUICtrlSetData($F1Prog1, Int(100*Round($dl_info[0]/$dl_info[1], 2)))
				EndIf
				If $dl_info[3] = True Then
					GUICtrlSetData($F1Label4, "下載音訊檔案... 100 % [" & $dl_info[0] & " bytes/ 下載完成]")
					$dl_count = $dl_count - 1
					ExitLoop
				EndIf
			EndIf
			Sleep(500)
		WEnd
		InetClose($file_handle)

		Local $command
		Local $pid

		FileMove($dlpath & "\" & $filename, $dlpath & "\temp.mp4")
		FileMove($dlpath & "\" & $audiofilename, $dlpath & "\temp.m4a")

		GUICtrlSetData($F1Label4, "合併影音檔案...")

		$command = """" & @WorkingDir & "\lib\MP4Box.exe" & """" & " " & "-add" & " " & """" & $dlpath & "\temp.mp4"":par=1:1" & " " & "-add" & " " & """" & $dlpath & "\temp.m4a""" & " " & "-new" & " " & """" & $dlpath & "\_Mux.mp4" & """"
		;$command = StringToBinary($command, 4)
		ConsoleWrite($command & @CRLF)
		;$pid = Run('"' & @ComSpec & '" /c /u ' & $command, '', @SW_HIDE, 2 + 4)
		$pid = RunWait($command, '', @SW_HIDE, 2 + 4)

		FileMove($dlpath & "\_Mux.mp4", $dlpath & "\" & $filename)
		FileDelete($dlpath & "\temp.mp4")
		FileDelete($dlpath & "\temp.m4a")

		If $pid = 0 Then
			GUICtrlSetData($F1Label4, "合併完成")
		Else
			GUICtrlSetData($F1Label4, "合併失敗，請嘗試手動合併")
		EndIf

	EndIf
	GUICtrlSetState($F1Button2, 64)

EndFunc