#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\icons\FormsIcon.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0
 Author:         myName

 Script Function:
	A simple video downloader and converter for Youtube

#ce ----------------------------------------------------------------------------

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
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include "_URLCodec.au3"
#include "_INETGetEX.au3"

Opt("GUIOnEventMode", 1)
Opt("MustDeclareVars", 1)
Opt("GUICloseOnESC", 0)

;global variables
Global $Form1
Global $video_url_box
Global $retrieve_button
Global $save_location
Global $browser_button
Global $opt_mux
Global $download_button
Global $watch_button
Global $dl_m4a_button
Global $dl_oga_button
Global $dl_sub_button
Global $about_button
Global $quality_opt_combo
Global $F1Group1
Global $F1Image1
Global $F1Label8
Global $F1Label9
Global $F1Label10
Global $F1Radio1
Global $F1Radio2
Global $title
Global $thumbnailfile

Global $fetch = 0
Global $sig

Global $method
Global $method1checked
Global $method2checked

Global $video_info_parsing

Global $format_count
Global $save_location_selector ;location of downloaded video
Global $video_id
Global $video_url
Global $video_url_info[25][2] ;array, [type, url]
Global $audio_url_info[10][2] ;array, [type, url]
Global $m4a_url
Global $oga_url

Global $Form2

;panic button
HotKeySet("^{BREAK}", "_Back")

;main function
_Main()
While 1
	Sleep(100)
WEnd


;panic button
Func _Back()
	If $fetch = 1 Then
		MsgBox(8208, "訊息", "使用者終止操作")
	EndIf
	$fetch = 0
	Return
EndFunc

;video info fetcher
Func _FetchVideoInfo()
	;some local vars
	Local $videoIE
	Local $parsed_video_url
	Local $video_info_url
	Local $video_embed_temp_file
	Local $video_embed_temp
	Local $sts
	Local $get_video_info
	Local $video_info
	Local $audio_info_parsing
	Local $author
	Local $duration
	Local $duration_min
	Local $video_url_temp[25] ;array
	Local $encodedtitle

	Local $i
	Local $j
	Local $k
	Local $l
	Local $m
	Local $n
	Local $o
	Local $p
	Local $q
	Local $r


	If $fetch = 0 Then
		FileDelete($get_video_info)
		FileDelete($thumbnailfile)
		Return
	EndIf

	$method1checked = GUICTrlRead($F1Radio1)
	$method2checked = GUICTrlRead($F1Radio2)
	If $method1checked = 1 Then
		$method = 2 ;方法一 繞過年齡限制 繞過版權限制
	ElseIf $method2checked = 1 Then
		$method = 1 ;方法二 下載鎖定影片或私人影片
	Else
		$method = 0
	EndIf

	#cs
	method 2


	#ce

	;GUICtrlSetImage($F1Image1, "")
	FileDelete($thumbnailfile)
	GUICtrlSetState($watch_button, 128)
	GUICtrlSetState($download_button, 128)
	GUICtrlSetState($opt_mux, 128)
	GUICtrlSetState($quality_opt_combo, 128)
	GUICtrlSetState($dl_m4a_button, 128)
	GUICtrlSetState($dl_oga_button, 128)

	$video_url = GUICtrlRead($video_url_box)


	;lengthen short youtube urls
	If StringInStr($video_url, "youtu.be") <> 0 Then
	   $parsed_video_url = StringSplit($video_url, "be/", 1)
	   $video_id = $parsed_video_url[2]
    ElseIf StringInStr($video_url, "youtube.com/watch") <> 0 Then
	   $parsed_video_url = StringSplit($video_url, "watch?v=", 1)
	   $video_id = $parsed_video_url[2]
    Else
	   MsgBox(8240, "訊息", "無效的影片地址")
	   ConsoleWrite("[error] Invalid video url.")
	   GUICtrlSetState($video_url_box, 256)
	   $fetch = 0
	   Return
    EndIf

	;get sts value via embed
	;method 2 大概也不需要STS
	$video_embed_temp_file = _WinAPI_GetTempFileName(@TempDir)
	InetGet("http://www.youtube.com/embed/" & $video_id, $video_embed_temp_file, $INET_FORCERELOAD, $INET_DOWNLOADWAIT)
	$video_embed_temp = FileRead($video_embed_temp_file)
	If StringInStr($video_embed_temp, """sts"":") <> 0 Then
		$video_embed_temp = StringSplit($video_embed_temp, """sts"":", 1)
		$video_embed_temp = $video_embed_temp[2]
		$video_embed_temp = StringSplit($video_embed_temp, ",", 1)
		If StringIsDigit($video_embed_temp) = 1 Then
			$sts = $video_embed_temp[1]
		Else
			$sts = StringTrimRight($video_embed_temp[1], 1)
		EndIf
	Else
		$sts = 0
	EndIf
	FileDelete($video_embed_temp_file)

	;get video info url
	If $method = 1 Then
		If $sts <> 0 Then
			$video_info_url = "http://www.youtube.com/get_video_info?eurl=http://github.com/&sts=" & $sts & "&video_id=" & $video_id
			ConsoleWrite("[debug] video info url: " & $video_info_url & @CRLF)
		Else
			$video_info_url = "http://www.youtube.com/get_video_info?eurl=http://github.com/&video_id=" & $video_id
		EndIf
	ElseIf $method = 2 Then
		$video_info_url = "http://www.youtube.com/watch?v=" & $video_id
		ConsoleWrite("[debug] video info url: " & $video_info_url & @CRLF)
	EndIf


	;get video info and parse it
	$get_video_info = _WinAPI_GetTempFileName(@TempDir)
	InetGet($video_info_url, $get_video_info, $INET_FORCERELOAD, $INET_DOWNLOADWAIT)
	$video_info = FileRead($get_video_info)
	;get title
	If $method = 1 Then
		If StringInStr($video_info, "title") <> 0 Then
			$video_info_parsing = StringSplit($video_info, "title=", 1)
			$video_info_parsing = StringSplit($video_info_parsing[2], "&", 1)
			$title = $video_info_parsing[1]
			$encodedtitle = $title
		Else
			$title = "N/A"
		EndIf
		$title = _URLDec($title, 4) ;percent decode title
	ElseIf $method = 2 Then
		If StringInStr($video_info, """title"":""") <> 0 Then
			$video_info_parsing = StringSplit($video_info, """title"":""", 1)
			$video_info_parsing = StringSplit($video_info_parsing[2], """,", 1)
			$video_info_parsing = StringSplit($video_info_parsing[1], """},", 1)
			$title = $video_info_parsing[1]
			;$encodedtitle = $title
		Else
			$title = "N/A"
		EndIf
	EndIf
	GUICtrlSetData($F1Label8, $title)

	;get author
	If $method = 1 Then
		If StringInStr($video_info, "author") <> 0 Then
			$video_info_parsing = StringSplit($video_info, "author=", 1)
			$video_info_parsing = StringSplit($video_info_parsing[2], "&", 1)
			$author = $video_info_parsing[1]
		Else
			$author = "N/A"
		EndIf
		$author = _URLDec($author, 4)
	ElseIf $method = 2 Then
		If StringInStr($video_info, """author"":""") <> 0 Then
			$video_info_parsing = StringSplit($video_info, """author"":""", 1)
			$video_info_parsing = StringSplit($video_info_parsing[2], """,", 1)
			$video_info_parsing = StringSplit($video_info_parsing[1], """},", 1)
			$author = $video_info_parsing[1]
			;$encodedtitle = $title
		Else
			$author = "N/A"
		EndIf
	EndIf
	GUICtrlSetData($F1Label9, $author)

	;get duration
	If $method = 1 Then
		If StringInStr($video_info, "length_seconds") <> 0 Then
			$video_info_parsing = StringSplit($video_info, "length_seconds=", 1)
			$video_info_parsing = StringSplit($video_info_parsing[2], "&", 1)
			$duration = $video_info_parsing[1]
		Else
			$duration = "N/A"
		EndIf
	ElseIf $method = 2 Then
		If StringInStr($video_info, """length_seconds"":""") <> 0 Then
			$video_info_parsing = StringSplit($video_info, """length_seconds"":""", 1)
			$video_info_parsing = StringSplit($video_info_parsing[2], """,", 1)
			$duration = $video_info_parsing[1]
			;$encodedtitle = $title
		Else
			$duration = "N/A"
		EndIf
	EndIf
	$duration_min = StringFormat("%02d", Int($duration / 86400)) & ":" & StringFormat("%02d", Mod(Int($duration / 3600), 24)) & ":" & StringFormat("%02d", Mod(Int($duration / 60), 60)) & ":" & StringFormat("%02d", Mod($duration, 60))
	GUICtrlSetData($F1Label10, $duration_min)

	;start parsing download urls
	If StringInStr($video_info, "url_encoded_fmt_stream_map") <> 0 Then
		If $method = 1 Then

			$video_info_parsing = StringSplit($video_info, "quality", 1)

			#cs
			grep quality (1quality2quality3.....) (take 2 to 0)
			from 2 to 0 grep url (quality2.....url2...) (take 2)


			;parser debug
			ConsoleWrite("grep quality" & @CRLF)
			For $i = 2 To $video_info_parsing[0]
				ConsoleWrite($video_info_parsing[$i] & @CRLF)
			Next
			#ce

			For $i = 2 To $video_info_parsing[0]
				$video_url_temp[$i] = StringSplit($video_info_parsing[$i], "url", 1)
				If UBound($video_url_temp[$i]) < 3 Then
					;MsgBox(8240, "訊息", "影片地址讀取異常，可能導致下載失敗，請重試(" & $i & ")")
					ConsoleWrite("[error] Invalid response. No url detected." & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If StringInStr(($video_url_temp[$i])[2], "googlevideo.com") = 0 Then
					;MsgBox(8240, "訊息", "影片地址讀取異常，伺服器回傳非影片的結果，請重試(" & $i & ")")
					ConsoleWrite("[error] Garbage in response. " & ($video_url_temp[$i])[2] & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If StringInStr(($video_url_temp[$i])[2], "mime%253Daudio") <> 0 Then
					;MsgBox(8240, "訊息", "影片地址讀取異常，伺服器回傳無效地址，請重試(" & $i & ")")
					ConsoleWrite("[error] Invalid response. " & ($video_url_temp[$i])[2] & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
			Next

			;parser debug
			#cs
			ConsoleWrite("grep url" & @CRLF)
			For $i = 2 To $video_info_parsing[0]
				ConsoleWrite(($video_url_temp[$i])[2] & @CRLF)
			Next
			#ce


			;strip rubbish
			ConsoleWrite("[message] Parsing response." & @CRLF)
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[2]
				If UBound(StringSplit($j, "%3D", 1)) >= 3 Then
					$j = (StringSplit($j, "%3D", 1))[2]
				Else
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(3d)")
					ConsoleWrite("[error] Parsing error. Retrying. (3d)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If UBound(StringSplit($j, "%2C", 1)) >= 2 Then
					$j = (StringSplit($j, "%2C", 1))[1]
				Else
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(2c)")
					ConsoleWrite("[error] Parsing error. Retrying. (2c)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If UBound(StringSplit($j, "%26", 1)) >= 2 Then
					$j = (StringSplit($j, "%26", 1))[1]
				Else
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(26)")
					ConsoleWrite("[error] Parsing Error. Retrying. (26)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				$j = _URLDec($j, 4)
				$j = _URLDec($j, 4)
				$k = _URLDec($j, 4)
				$k = _URLDec($k, 4)
				$k = _URLDec($k, 4)
				If StringInStr($j, "http") <> 1 Then
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(3d)")
					ConsoleWrite("[error] Parsing Error. Retrying. (3d)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				;if signature is not available, search for s instead
				If StringInStr($j, "signature") = 0 Then
					;The only way to tell that the signature is ciphered, is if the URLs in the map contain "s=" instead of "sig=".
					;MsgBox(8240, "訊息", "影片金鑰讀取失敗，請重試(sign)")
					;ConsoleWrite("error" & @CRLF)
					;FileDelete($get_video_info)
					;Return
					;get signature
					If StringInStr(($video_url_temp[$i])[1], "s%3D") <> 0 Then
						$l = 1
						$j = ($video_url_temp[$i])[1]
						$j = StringMid($j, StringInStr($j, "%26s%3D"))
						;$j = StringMid($j, StringInStr($j, "itag%253D"))
						$j = StringReplace($j, "%26s%3D", "")
						$j = (StringSplit($j, "%26", 1))[1]
						;$j = (StringSplit($j, "26", 1))[1]
						;$j = (StringSplit($j, "%2C", 1))[1]
						;$j = (StringSplit($j, "&", 1))[1]
						;$video_url_info[$i][0] = $video_url_info[$i][0] & " itag=" & $j
						If $j = "" Then
							;MsgBox(8240, "訊息", "影片金鑰讀取失敗，請重試或嘗試使用方法二破解(sig)")
							ConsoleWrite("[error] Failed to obtain signature. Retrying." & @CRLF)
							FileDelete($thumbnailfile)
							FileDelete($get_video_info)
							Return
						EndIf

						;use online decipher service??? or shall i implement it by myself
						$j = _SigDec($j)


						ConsoleWrite("[message] Decrypted Signature: " & $j & @CRLF)
						$k = $k & "&signature=" & $j
					Else
						;MsgBox(8240, "訊息", "影片金鑰讀取失敗，請重試(s)")
						ConsoleWrite("[error] Failed to obtain ciphered signature. Retrying." & @CRLF)
						FileDelete($thumbnailfile)
						FileDelete($get_video_info)
						Return
					EndIf
				EndIf


				$k = $k & "&title=" & $encodedtitle
				$video_url_info[$i][1] = $k
				ConsoleWrite("[message] Video url obtained. " & $video_url_info[$i][1] & @CRLF)
				ConsoleWrite("[message] Checking url validity. " & @CRLF)
				$m = InetGetSize ( $video_url_info[$i][1], 1)
				If $m = 0 Then
					ConsoleWrite("[message] Invalid url detected. Refetching. " & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
			Next
			If $l = 1 Then
				;MsgBox(8240, "訊息", "請注意，已取得影片地址，由於本影片有加密，無法下載(sign)")
				ConsoleWrite("[message] Signature deciphered." & @CRLF)
			EndIf

			;get video resolution(p)
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[1]
				$j = (StringSplit($j, "%3D", 1))[2]
				$j = (StringSplit($j, "%26", 1))[1]
				$j = (StringSplit($j, "%2C", 1))[1]
				$j = (StringSplit($j, "&", 1))[1]
				$video_url_info[$i][0] = $j
				;ConsoleWrite($video_url_info[$i][0] & @CRLF)
			Next
			;get mime
			For $i = 2 To $video_info_parsing[0]
				If StringInStr($video_url_info[$i][1], "mime=") <> 0 Then
					$j = (StringSplit($video_url_info[$i][1], "mime=", 1))[2]
					$j = (StringSplit($j, "&", 1))[1]
					$video_url_info[$i][0] = $video_url_info[$i][0] & " (" & $j & ")"
					;ConsoleWrite($video_url_info[$i][0] & @CRLF)
				EndIf
			Next
			;get video itag value
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[2]
				$j = StringMid($j, StringInStr($j, "itag"))
				$j = StringMid($j, StringInStr($j, "itag%253D"))
				$j = StringReplace($j, "itag%253D", "")
				$j = (StringSplit($j, "%", 1))[1]
				;$j = (StringSplit($j, "26", 1))[1]
				;$j = (StringSplit($j, "%2C", 1))[1]
				;$j = (StringSplit($j, "&", 1))[1]
				$video_url_info[$i][0] = $video_url_info[$i][0] & " itag=" & $j
				ConsoleWrite("[message] Video mime type obtained. " & $video_url_info[$i][0] & @CRLF)
			Next

			$format_count= $video_info_parsing[0]

			;find audio
			Local $audiocount = 1
			Local $last


			$video_info_parsing = StringSplit($video_info, "&adaptive_fmts=", 1)

			If UBound($video_info_parsing) >= 3 Then
				$i = StringSplit($video_info_parsing[2], "%3D", 1)
				$i = $i[1]
				ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)




				$video_info_parsing = (StringSplit($video_info, "&adaptive_fmts=", 1))[2]
				$video_info_parsing = (StringSplit($video_info_parsing, "&", 1))[1]
				ConsoleWrite("[debug] raw " & $video_info_parsing & @CRLF)
				If StringInStr($i, "s") = 1 AND StringInStr($i, "size") = 0 Then
					$k = ("%2C" & $i & "%3D")
					$video_info_parsing = StringSplit($video_info_parsing, $k, 1)
					ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)
					ConsoleWrite("[debug] Video info parsing is " & $video_info_parsing[0] & @CRLF)
					$video_info_parsing[1] = StringReplace($video_info_parsing[1], $i & "%3D", "")
					For $j = 1 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = ($video_info_parsing[$j] & "%2C")
					Next
					Local $ktemp[UBound($video_info_parsing) + 1]
					For $j = 2 To ($video_info_parsing[0] + 1)
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$ktemp[$j] = $video_info_parsing[$j - 1]
					Next
					ReDim $video_info_parsing[UBound($ktemp)]
					$video_info_parsing[0] = UBound($ktemp) - 1
					For $j = 2 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = $ktemp[$j]
					Next
				ElseIf StringInStr($i, "type") = 1 Then
					$k = ("%2C" & $i & "%3D")
					$video_info_parsing = StringSplit($video_info_parsing, $k, 1)
					ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)
					ConsoleWrite("[debug] Video info parsing is " & $video_info_parsing[0] & @CRLF)
					$video_info_parsing[1] = StringReplace($video_info_parsing[1], $i & "%3D", "")
					For $j = 1 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = ($video_info_parsing[$j] & "%2C")
					Next
					Local $ktemp[UBound($video_info_parsing) + 1]
					For $j = 2 To ($video_info_parsing[0] + 1)
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$ktemp[$j] = $video_info_parsing[$j - 1]
					Next
					ReDim $video_info_parsing[UBound($ktemp)]
					$video_info_parsing[0] = UBound($ktemp) - 1
					For $j = 2 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = $ktemp[$j]
					Next
				Else
					$video_info_parsing = StringSplit($video_info_parsing, $i & "%3D", 1)
				EndIf

				$audio_info_parsing = $video_info_parsing

				Local $newi


				For $j = 2 To $video_info_parsing[0]
					$audio_info_parsing[$j] = $video_info_parsing[$j]
					$video_info_parsing[$j] = $i & "%3D" & $video_info_parsing[$j]
					ConsoleWrite("[debug] Url encoded adaptive stream map: " & $video_info_parsing[$j] & @CRLF)
					If StringInStr($video_info_parsing[$j], "audio%252F") = 0 Then
						ConsoleWrite("[message] No audio found. Continue loop." & @CRLF)
						ContinueLoop
					EndIf
					$audiocount = $audiocount + 1

					$video_info_parsing[$j] = (StringSplit($audio_info_parsing[$j - 1], "%2C", 1))[2] & $video_info_parsing[$j]
					ConsoleWrite("[debug] Url encoded adaptive stream map: " & $video_info_parsing[$j] & @CRLF)
					$video_info_parsing[$j] = (StringSplit($video_info_parsing[$j], "%2C", 1))[1]
					$newi = $i
					$i = (StringSplit($video_info_parsing[$j], "%3D", 1))[1]
					$video_info_parsing[$j] = "%26" & $video_info_parsing[$j]

					;If StringInStr($i, "url") = 0 Then
						$last = StringSplit($video_info_parsing[$j], "url", 1)
						$last = StringSplit($last[2], "%26", 1)
						If UBound($last) >= 3 Then
							$last = (StringSplit($last[2], "%3D"))[1]
						Else
							$last = ""
						EndIf
						ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
						;$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "%2C", "")
						;$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "%26", "&")

						$video_info_parsing[$j] = StringSplit($video_info_parsing[$j], "%26url%3D", 1)

						If UBound($video_info_parsing[$j]) >= 3 Then
							$k = ($video_info_parsing[$j])[2] & ($video_info_parsing[$j])[1]
						Else
							$k = ($video_info_parsing[$j])[1]
						EndIf
						$k = _URLDec($k)
						$video_info_parsing[$j] = _URLDec($k)
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
						#cs
					Else
						;$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
						$last = StringSplit($video_info_parsing[$j], "\u0026", 1)
						$last = (StringSplit($last[2], "="))[1]
						ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], ",", "")
						;$k = (StringSplit($video_info_parsing[$j], "\u0026", 1))[2]
						;$k = (StringSplit($k, "=", 1))[1]
						;$i = $k
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "\u0026", "&")
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
					EndIf
					#ce

					ConsoleWrite("[debug] Decoded URL map: " & $video_info_parsing[$j] & @CRLF)
					If $i = "type" Then
						$k = (StringSplit($video_info_parsing[$j], "type=", 1))[2]
					Else
						$k = (StringSplit($video_info_parsing[$j], "&type=", 1))[2]
					EndIf
					$k = StringSplit($k, "&", 1)
					;If StringInStr($k[1], "audio") <> 0 Then
					;	$audiocount = $audiocount + 1
					;	ConsoleWrite("[message] Audio file found. Continue loop." & @CRLF)
					;	ContinueLoop
					;EndIf
					$audio_url_info[$audiocount][0] = $k[1]

					;$k = (StringSplit($video_info_parsing[$j], "quality_label=", 1))[2]
					;$k = StringSplit($k, "&", 1)
					;$audio_url_info[$audiocount][0] = $audio_url_info[$audiocount][0]




					If StringInStr($video_info_parsing[$j], "signature") = 0 Then
						ConsoleWrite("[message] Ciphered signature found." & @CRLF)
						$k = StringSplit($video_info_parsing[$j], "&s=", 1)    ; k[1] &s= k[2](l[1]) & l[2]

						#cs
						  k[1] &s= k[2](l[1]) & l[2]
						  k[1] & l[2]
						  strip $i .........


						  k[1] &s= k[2]



						#ce

						If StringInStr($k[2], "&") <> 0 Then
							$l = (StringSplit($k[2], "&", 1))
							ConsoleWrite("[message] Ciphered signature: " & $l[1] & @CRLF)
							$m = _SigDec($l[1])
							$o = ""
							For $n = 2 To $l[0]
								$o = $o & $l[$n]
							Next
							$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							If $last <> "" Then
								$k = $video_info_parsing[$j]
								ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
							Else
								$k = $video_info_parsing[$j]
								ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
							EndIf
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
						Else
							ConsoleWrite("[message] Ciphered sighature: " & $k[2] & @CRLF)
							$m = _SigDec($k[2]) ;
							;$video_info_parsing[$j] =


							$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							If $last <> "" Then
								$l = $video_info_parsing[$j]
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $last & "="), 0, -1) - 1))
							Else
								$l = $video_info_parsing[$j]
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $i & "="), 0 -1) - 1))
							EndIf
							;$video_info_parsing[$j] = $k[1] & "&signature=" & $m
							;ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
						EndIf
					Else
						If $last <> "" Then
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
						Else
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
						EndIf
					EndIf

					$audio_url_info[$audiocount][1] = $video_info_parsing[$j]

					ConsoleWrite("[debug] Url: " & $audio_url_info[$audiocount][1] & @CRLF)
					ConsoleWrite("[debug] Quality Found: " & $audio_url_info[$audiocount][0] & @CRLF)
					$i = $newi
				Next

				;Local $format_count_2

				;$format_count_2 = $video_info_parsing[0] - $audiocount - 1

				;$video_info_parsing[0] = $video_info_parsing[0] - $audiocount + $format_count
			Else
				ConsoleWrite("[message] No DASH audio detected. Skip this part." & @CRLF)
				$j = 1
				;$video_info_parsing[0] = $format_count + 1
			EndIf



			For $i = 1 To $audiocount
				If StringInStr($audio_url_info[$i][0], "mp4a") <> 0 Then
					ConsoleWrite("[message] m4a url: " & $audio_url_info[$i][1] & @CRLF)
					$m4a_url = $audio_url_info[$i][1]
					$j = 1
					GUICtrlSetState($dl_m4a_button, 64)
				ElseIf StringInStr($audio_url_info[$i][0], "vorbis") <> 0 Then
					ConsoleWrite("[message] oga url: " & $audio_url_info[$i][1] & @CRLF)
					$oga_url = $audio_url_info[$i][1]
					$j = 1
					GUICtrlSetState($dl_oga_button, 64)
				EndIf
			Next

			If $j <> 1 Then
				ConsoleWrite("[message] No DASH audio detected. Retrying." & @CRLF)
				FileDelete($thumbnailfile)
				FileDelete($get_video_info)
				Return
			EndIf






			GUICtrlSetState($watch_button, 64)
			GUICtrlSetState($download_button, 64)
			GUICtrlSetState($opt_mux, 64)
			GUICtrlSetState($quality_opt_combo, 64)
			$k = ""
			For $i = 2 To $format_count
				$k = $k & "|" & $video_url_info[$i][0]
			Next
			GUICtrlSetData($quality_opt_combo, $k)
			GUICtrlSetState($dl_sub_button, 64)
			#cs
			itag%253D
			itag%25252C

			mp4影音部分很安定，影音部分會亂跑
			檢查144p itag必須=160，不合報錯

			#ce

			#cs
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[2]
				$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = $j & "title=" & $encodedtitle
				;$j =
				#cs
				$j = StringReplace($j, "&itag", "&itag")
				If @extended > 1 Then
					$k = (StringSplit($j, "&itag=", 1))[2]
					$k = (StringSplit($k, "&", 1))[1]
					ConsoleWrite($k & @CRLF)
					$j = StringReplace($j, "&itag=$k", "")
				EndIf

				$j = StringReplace($j, "&itag", "&itag")
				If @extended > 1 Then
					$k = (StringSplit($j, "&itag=", 1))[2]
					$k = (StringSplit($k, "&", 1))[1]
					ConsoleWrite($k & @CRLF)
					$j = StringReplace($j, "&itag=$k", "")
				EndIf
				#ce

				;If StringInStr($j, ",', 0, -1) <> 0 Then
				;	If

				If StringInStr($j, "=http") <> 1 Then
					MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(3d)")
					ConsoleWrite("error" & @CRLF)
					FileDelete($get_video_info)
					Return
				EndIf
				If StringInStr($j, "%2Fr") = 0 Then
					MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(2Fr)")
					ConsoleWrite("error" & @CRLF)
					FileDelete($get_video_info)
					Return
				EndIf

				ConsoleWrite($j & @CRLF)
			Next
			#ce
		ElseIf $method = 2 Then

			Local $last

			$audio_info_parsing = $video_info_parsing


			;find fmt first (obtain pattern

			$video_info_parsing = StringSplit($video_info, """url_encoded_fmt_stream_map"":""", 1)
			If UBound($video_info_parsing) < 3 Then
				ConsoleWrite("[error] Invalid response. No url detected." & @CRLF)
				FileDelete($thumbnailfile)
				FileDelete($get_video_info)
				Return
			EndIf

			$i = StringSplit($video_info_parsing[2], "=", 1)
			$i = $i[1]
			ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)




			$video_info_parsing = (StringSplit($video_info, """url_encoded_fmt_stream_map"":""", 1))[2]
			$video_info_parsing = (StringSplit($video_info_parsing, """", 1))[1]
			$video_info_parsing = StringSplit($video_info_parsing, $i & "=", 1)






			For $j = 2 To $video_info_parsing[0]
				ConsoleWrite("[debug] Url encoded fmt stream map: " & $video_info_parsing[$j] & @CRLF)
				If StringInStr($i, "url") = 0 Then
					$last = StringSplit($video_info_parsing[$j], "url", 1)
					$last = StringSplit($last[2], "\u0026", 1)
					If UBound($last) >= 3 Then
						$last = (StringSplit($last[2], "="))[1]
					Else
						$last = ""
					EndIf
					ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
					$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
					$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], ",", "")
					$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "\u0026", "&")
					$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
					$video_info_parsing[$j] = StringSplit($video_info_parsing[$j], "&url=", 1)
					$k = ($video_info_parsing[$j])[2] & ($video_info_parsing[$j])[1]
					$video_info_parsing[$j] = _URLDec($k)
				Else
					;$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
					$last = StringSplit($video_info_parsing[$j], "\u0026", 1)
					$last = (StringSplit($last[2], "="))[1]
					ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
					$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], ",", "")
					;$k = (StringSplit($video_info_parsing[$j], "\u0026", 1))[2]
					;$k = (StringSplit($k, "=", 1))[1]
					;$i = $k
					$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "\u0026", "&")
					$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
					$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
				EndIf

				$k = (StringSplit($video_info_parsing[$j], "quality=", 1))[2]
				$k = StringSplit($k, "&", 1)
				$video_url_info[$j][0] = $k[1]

				$k = (StringSplit($video_info_parsing[$j], "type=", 1))[2]
				$k = StringSplit($k, "&", 1)
				$video_url_info[$j][0] = $video_url_info[$j][0] & " " & $k[1]


				If StringInStr($video_info_parsing[$j], "signature") = 0 Then
					ConsoleWrite("[message] Ciphered signature found." & @CRLF)
					$k = StringSplit($video_info_parsing[$j], "&s=", 1)    ; k[1] &s= k[2](l[1]) & l[2]

					#cs
					  k[1] &s= k[2](l[1]) & l[2]
					  k[1] & l[2]
					  strip $i .........


					  k[1] &s= k[2]



					#ce

					If StringInStr($k[2], "&") <> 0 Then
						$l = (StringSplit($k[2], "&", 1))
						ConsoleWrite("[message] Ciphered signature: " & $l[1] & @CRLF)
						$m = _SigDec($l[1])
						$o = ""
						For $n = 2 To $l[0]
							$o = $o & $l[$n]
						Next
						$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
						ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
						If $last <> "" Then
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
						Else
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
						EndIf
						ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
						$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
					Else
						ConsoleWrite("[message] Ciphered sighature: " & $k[2] & @CRLF)
						$m = _SigDec($k[2]) ;
						;$video_info_parsing[$j] =


						$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
						ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
						If $last <> "" Then
							$l = $video_info_parsing[$j]
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $last & "="), 0, -1) - 1))
						Else
							$l = $video_info_parsing[$j]
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $i & "="), 0 -1) - 1))
						EndIf
						;$video_info_parsing[$j] = $k[1] & "&signature=" & $m
						;ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
						$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
					EndIf
				Else
					If $last <> "" Then
						$k = $video_info_parsing[$j]
						ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
						$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
					Else
						$k = $video_info_parsing[$j]
						ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
						$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
					EndIf
				EndIf


				$video_url_info[$j][1] = $video_info_parsing[$j]

				ConsoleWrite("[debug] Url: " & $video_url_info[$j][1] & @CRLF)
				ConsoleWrite("[debug] Quality Found: " & $video_url_info[$j][0] & @CRLF)
			Next

			$format_count = $video_info_parsing[0] - 1



			;find adaptive

			$video_info_parsing = StringSplit($video_info, """adaptive_fmts"":""", 1)

			If UBound($video_info_parsing) >= 3 Then
				$i = StringSplit($video_info_parsing[2], "=", 1)
				$i = $i[1]
				ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)




				$video_info_parsing = (StringSplit($video_info, """adaptive_fmts"":""", 1))[2]
				$video_info_parsing = (StringSplit($video_info_parsing, """", 1))[1]
				ConsoleWrite("[debug] raw " & $video_info_parsing & @CRLF)
				If StringInStr($i, "s") = 1 AND StringInStr($i, "size") = 0 Then
					$k = ("," & $i & "=")
					$video_info_parsing = StringSplit($video_info_parsing, $k, 1)
					ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)
					ConsoleWrite("[debug] Video info parsing is " & $video_info_parsing[0] & @CRLF)
					$video_info_parsing[1] = StringReplace($video_info_parsing[1], $i & "=", "")
					For $j = 1 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = ($video_info_parsing[$j] & ",")
					Next
					Local $ktemp[UBound($video_info_parsing) + 1]
					For $j = 2 To ($video_info_parsing[0] + 1)
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$ktemp[$j] = $video_info_parsing[$j - 1]
					Next
					ReDim $video_info_parsing[UBound($ktemp)]
					$video_info_parsing[0] = UBound($ktemp) - 1
					For $j = 2 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = $ktemp[$j]
					Next
				ElseIf StringInStr($i, "type") = 1 Then
					$k = ("," & $i & "=")
					$video_info_parsing = StringSplit($video_info_parsing, $k, 1)
					ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)
					ConsoleWrite("[debug] Video info parsing is " & $video_info_parsing[0] & @CRLF)
					$video_info_parsing[1] = StringReplace($video_info_parsing[1], $i & "=", "")
					For $j = 1 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = ($video_info_parsing[$j] & ",")
					Next
					Local $ktemp[UBound($video_info_parsing) + 1]
					For $j = 2 To ($video_info_parsing[0] + 1)
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$ktemp[$j] = $video_info_parsing[$j - 1]
					Next
					ReDim $video_info_parsing[UBound($ktemp)]
					$video_info_parsing[0] = UBound($ktemp) - 1
					For $j = 2 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = $ktemp[$j]
					Next
				Else
					$video_info_parsing = StringSplit($video_info_parsing, $i & "=", 1)
				EndIf



				Local $audiocount = 0

				For $j = 2 To $video_info_parsing[0]
					ConsoleWrite("[debug] Url encoded adaptive stream map: " & $video_info_parsing[$j] & @CRLF)
					If StringInStr($video_info_parsing[$j], "video%2F") = 0 Then
						$audiocount = $audiocount + 1
						ConsoleWrite("[message] No video found. Continue loop." & @CRLF)
						ContinueLoop
					EndIf

					If StringInStr($i, "url") = 0 Then
						$last = StringSplit($video_info_parsing[$j], "url", 1)
						$last[2] = (StringSplit($last[2], ",", 1))[1]
						$last = StringSplit($last[2], "\u0026", 1)
						If UBound($last) >= 3 Then
							$last = (StringSplit($last[2], "="))[1]
						Else
							$last = ""
						EndIf
						ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
						$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
						$video_info_parsing[$j] = (StringSplit($video_info_parsing[$j], ",", 1))[1]
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "\u0026", "&")
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
						$video_info_parsing[$j] = StringSplit($video_info_parsing[$j], "&url=", 1)
						$k = ($video_info_parsing[$j])[2] & ($video_info_parsing[$j])[1]
						$video_info_parsing[$j] = _URLDec($k)
					Else
						;$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
						$last = StringSplit($video_info_parsing[$j], "\u0026", 1)
						$last = (StringSplit($last[2], "="))[1]
						ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
						$video_info_parsing[$j] = (StringSplit($video_info_parsing[$j], ",", 1))[1]
						;$k = (StringSplit($video_info_parsing[$j], "\u0026", 1))[2]
						;$k = (StringSplit($k, "=", 1))[1]
						;$i = $k
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "\u0026", "&")
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
					EndIf

					If StringInStr($i, "type") = 1 Then
						$k = (StringSplit($video_info_parsing[$j], "&type=", 1))[2]
					Else
						$k = (StringSplit($video_info_parsing[$j], "&type=", 1))[2]
					EndIf
					$k = StringSplit($k, "&", 1)
					;If StringInStr($k[1], "audio") <> 0 Then
					;	$audiocount = $audiocount + 1
					;	ConsoleWrite("[message] Audio file found. Continue loop." & @CRLF)
					;	ContinueLoop
					;EndIf
					$video_url_info[$j + $format_count][0] = $k[1]

					$k = (StringSplit($video_info_parsing[$j], "quality_label=", 1))[2]
					$k = StringSplit($k, "&", 1)
					$video_url_info[$j + $format_count][0] = $k[1] & " " & $video_url_info[$j + $format_count][0]




					If StringInStr($video_info_parsing[$j], "signature") = 0 Then
						ConsoleWrite("[message] Ciphered signature found." & @CRLF)
						$k = StringSplit($video_info_parsing[$j], "&s=", 1)    ; k[1] &s= k[2](l[1]) & l[2]

						#cs
						  k[1] &s= k[2](l[1]) & l[2]
						  k[1] & l[2]
						  strip $i .........


						  k[1] &s= k[2]



						#ce

						If StringInStr($k[2], "&") <> 0 Then
							$l = (StringSplit($k[2], "&", 1))
							ConsoleWrite("[message] Ciphered signature: " & $l[1] & @CRLF)
							$m = _SigDec($l[1])
							$o = ""
							For $n = 2 To $l[0]
								$o = $o & $l[$n]
							Next
							$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							If $last <> "" Then
								$k = $video_info_parsing[$j]
								ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
							Else
								$k = $video_info_parsing[$j]
								ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
							EndIf
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
						Else
							ConsoleWrite("[message] Ciphered sighature: " & $k[2] & @CRLF)
							$m = _SigDec($k[2]) ;
							;$video_info_parsing[$j] =


							$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							If $last <> "" Then
								$l = $video_info_parsing[$j]
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $last & "="), 0, -1) - 1))
							Else
								$l = $video_info_parsing[$j]
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $i & "="), 0 -1) - 1))
							EndIf
							;$video_info_parsing[$j] = $k[1] & "&signature=" & $m
							;ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
						EndIf
					Else
						If $last <> "" Then
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
						Else
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
						EndIf
					EndIf

					$video_url_info[$j + $format_count][1] = $video_info_parsing[$j]

					ConsoleWrite("[debug] Url: " & $video_url_info[$j + $format_count][1] & @CRLF)
					ConsoleWrite("[debug] Quality Found: " & $video_url_info[$j + $format_count][0] & @CRLF)
				Next

				Local $format_count_2

				$format_count_2 = $video_info_parsing[0] - $audiocount - 1

				$video_info_parsing[0] = $video_info_parsing[0] - $audiocount + $format_count
				$format_count = $video_info_parsing[0]
			Else
				ConsoleWrite("[message] No DASH video detected. Skip this part." & @CRLF)
				$video_info_parsing[0] = $format_count + 1
				$format_count = $video_info_parsing[0]
			EndIf




			;find audio
			Local $audiocount = 1

			$video_info_parsing = StringSplit($video_info, """adaptive_fmts"":""", 1)

			If UBound($video_info_parsing) >= 3 Then
				$i = StringSplit($video_info_parsing[2], "=", 1)
				$i = $i[1]
				ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)




				$video_info_parsing = (StringSplit($video_info, """adaptive_fmts"":""", 1))[2]
				$video_info_parsing = (StringSplit($video_info_parsing, """", 1))[1]
				ConsoleWrite("[debug] raw " & $video_info_parsing & @CRLF)
				If StringInStr($i, "s") = 1 AND StringInStr($i, "size") = 0 Then
					$k = ("," & $i & "=")
					$video_info_parsing = StringSplit($video_info_parsing, $k, 1)
					ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)
					ConsoleWrite("[debug] Video info parsing is " & $video_info_parsing[0] & @CRLF)
					$video_info_parsing[1] = StringReplace($video_info_parsing[1], $i & "=", "")
					For $j = 1 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = ($video_info_parsing[$j] & ",")
					Next
					Local $ktemp[UBound($video_info_parsing) + 1]
					For $j = 2 To ($video_info_parsing[0] + 1)
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$ktemp[$j] = $video_info_parsing[$j - 1]
					Next
					ReDim $video_info_parsing[UBound($ktemp)]
					$video_info_parsing[0] = UBound($ktemp) - 1
					For $j = 2 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = $ktemp[$j]
					Next
				ElseIf StringInStr($i, "type") = 1 Then
					$k = ("," & $i & "=")
					$video_info_parsing = StringSplit($video_info_parsing, $k, 1)
					ConsoleWrite("[debug] First Parameter is " & $i & @CRLF)
					ConsoleWrite("[debug] Video info parsing is " & $video_info_parsing[0] & @CRLF)
					$video_info_parsing[1] = StringReplace($video_info_parsing[1], $i & "=", "")
					For $j = 1 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = ($video_info_parsing[$j] & ",")
					Next
					Local $ktemp[UBound($video_info_parsing) + 1]
					For $j = 2 To ($video_info_parsing[0] + 1)
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$ktemp[$j] = $video_info_parsing[$j - 1]
					Next
					ReDim $video_info_parsing[UBound($ktemp)]
					$video_info_parsing[0] = UBound($ktemp) - 1
					For $j = 2 To ($video_info_parsing[0])
						ConsoleWrite("[debug] Debug point " & @CRLF)
						$video_info_parsing[$j] = $ktemp[$j]
					Next
				Else
					$video_info_parsing = StringSplit($video_info_parsing, $i & "=", 1)
				EndIf


				Local $newi


				For $j = 2 To $video_info_parsing[0]
					$audio_info_parsing[$j] = $video_info_parsing[$j]
					$video_info_parsing[$j] = $i & "=" & $video_info_parsing[$j]
					ConsoleWrite("[debug] Url encoded adaptive stream map: " & $video_info_parsing[$j] & @CRLF)
					If StringInStr($video_info_parsing[$j], "audio%2F") = 0 Then
						ConsoleWrite("[message] No audio found. Continue loop." & @CRLF)
						ContinueLoop
					EndIf
					$audiocount = $audiocount + 1

					$video_info_parsing[$j] = (StringSplit($audio_info_parsing[$j - 1], ",", 1))[2] & $video_info_parsing[$j]
					ConsoleWrite("[debug] Url encoded adaptive stream map: " & $video_info_parsing[$j] & @CRLF)
					$video_info_parsing[$j] = (StringSplit($video_info_parsing[$j], ",", 1))[1]
					$newi = $i
					$i = (StringSplit($video_info_parsing[$j], "=", 1))[1]
					$video_info_parsing[$j] = "\u0026" & $video_info_parsing[$j]

					;If StringInStr($i, "url") = 0 Then
						$last = StringSplit($video_info_parsing[$j], "url", 1)
						$last = StringSplit($last[2], "\u0026", 1)
						If UBound($last) >= 3 Then
							$last = (StringSplit($last[2], "="))[1]
						Else
							$last = ""
						EndIf
						ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
						;$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], ",", "")
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "\u0026", "&")
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
						$video_info_parsing[$j] = StringSplit($video_info_parsing[$j], "&url=", 1)
						If UBound($video_info_parsing[$j]) >= 3 Then
							$k = ($video_info_parsing[$j])[2] & ($video_info_parsing[$j])[1]
						Else
							$k = ($video_info_parsing[$j])[1]
						EndIf
						$video_info_parsing[$j] = _URLDec($k)
						#cs
					Else
						;$video_info_parsing[$j] = "&" & $i & "=" & $video_info_parsing[$j]
						$last = StringSplit($video_info_parsing[$j], "\u0026", 1)
						$last = (StringSplit($last[2], "="))[1]
						ConsoleWrite("[debug] First Parameter after url is " & $last & @CRLF)
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], ",", "")
						;$k = (StringSplit($video_info_parsing[$j], "\u0026", 1))[2]
						;$k = (StringSplit($k, "=", 1))[1]
						;$i = $k
						$video_info_parsing[$j] = StringReplace($video_info_parsing[$j], "\u0026", "&")
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
						$video_info_parsing[$j] = _URLDec($video_info_parsing[$j])
					EndIf
					#ce

					ConsoleWrite("[debug] Decoded URL map: " & $video_info_parsing[$j] & @CRLF)
					If $i = "type" Then
						$k = (StringSplit($video_info_parsing[$j], "type=", 1))[2]
					Else
						$k = (StringSplit($video_info_parsing[$j], "&type=", 1))[2]
					EndIf
					$k = StringSplit($k, "&", 1)
					;If StringInStr($k[1], "audio") <> 0 Then
					;	$audiocount = $audiocount + 1
					;	ConsoleWrite("[message] Audio file found. Continue loop." & @CRLF)
					;	ContinueLoop
					;EndIf
					$audio_url_info[$audiocount][0] = $k[1]

					;$k = (StringSplit($video_info_parsing[$j], "quality_label=", 1))[2]
					;$k = StringSplit($k, "&", 1)
					;$audio_url_info[$audiocount][0] = $audio_url_info[$audiocount][0]




					If StringInStr($video_info_parsing[$j], "signature") = 0 Then
						ConsoleWrite("[message] Ciphered signature found." & @CRLF)
						$k = StringSplit($video_info_parsing[$j], "&s=", 1)    ; k[1] &s= k[2](l[1]) & l[2]

						#cs
						  k[1] &s= k[2](l[1]) & l[2]
						  k[1] & l[2]
						  strip $i .........


						  k[1] &s= k[2]



						#ce

						If StringInStr($k[2], "&") <> 0 Then
							$l = (StringSplit($k[2], "&", 1))
							ConsoleWrite("[message] Ciphered signature: " & $l[1] & @CRLF)
							$m = _SigDec($l[1])
							$o = ""
							For $n = 2 To $l[0]
								$o = $o & $l[$n]
							Next
							$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							If $last <> "" Then
								$k = $video_info_parsing[$j]
								ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
							Else
								$k = $video_info_parsing[$j]
								ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
							EndIf
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
						Else
							ConsoleWrite("[message] Ciphered sighature: " & $k[2] & @CRLF)
							$m = _SigDec($k[2]) ;
							;$video_info_parsing[$j] =


							$video_info_parsing[$j] = $k[1] & "&s=" & $k[2]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							If $last <> "" Then
								$l = $video_info_parsing[$j]
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $last & "="), 0, -1) - 1))
							Else
								$l = $video_info_parsing[$j]
								$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($l, ("&" & $i & "="), 0 -1) - 1))
							EndIf
							;$video_info_parsing[$j] = $k[1] & "&signature=" & $m
							;ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = $video_info_parsing[$j] & "&signature=" & $m
						EndIf
					Else
						If $last <> "" Then
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $last & "="), 0, -1) - 1))
						Else
							$k = $video_info_parsing[$j]
							ConsoleWrite("[debug] " & $video_info_parsing[$j] & @CRLF)
							$video_info_parsing[$j] = StringLeft($video_info_parsing[$j], (StringInstr($k, ("&" & $i & "="), 0, -1) - 1))
						EndIf
					EndIf

					$audio_url_info[$audiocount][1] = $video_info_parsing[$j]

					ConsoleWrite("[debug] Url: " & $audio_url_info[$audiocount][1] & @CRLF)
					ConsoleWrite("[debug] Quality Found: " & $audio_url_info[$audiocount][0] & @CRLF)
					$i = $newi
				Next

				;Local $format_count_2

				;$format_count_2 = $video_info_parsing[0] - $audiocount - 1

				;$video_info_parsing[0] = $video_info_parsing[0] - $audiocount + $format_count
			Else
				ConsoleWrite("[message] No DASH audio detected. Skip this part." & @CRLF)
				$j = 1
				;$video_info_parsing[0] = $format_count + 1
			EndIf



			For $i = 1 To $audiocount
				If StringInStr($audio_url_info[$i][0], "mp4a") <> 0 Then
					ConsoleWrite("[message] m4a url: " & $audio_url_info[$i][1] & @CRLF)
					$m4a_url = $audio_url_info[$i][1]
					$j = 1
					GUICtrlSetState($dl_m4a_button, 64)
				ElseIf StringInStr($audio_url_info[$i][0], "vorbis") <> 0 Then
					ConsoleWrite("[message] oga url: " & $audio_url_info[$i][1] & @CRLF)
					$oga_url = $audio_url_info[$i][1]
					$j = 1
					GUICtrlSetState($dl_oga_button, 64)
				EndIf
			Next

			If $j <> 1 Then
				ConsoleWrite("[message] No DASH audio detected. Retrying." & @CRLF)
				FileDelete($thumbnailfile)
				FileDelete($get_video_info)
				Return
			EndIf


			GUICtrlSetState($watch_button, 64)
			GUICtrlSetState($download_button, 64)
			GUICtrlSetState($opt_mux, 64)
			GUICtrlSetState($quality_opt_combo, 64)
			$k = ""
			For $i = 2 To $format_count
				$k = $k & "|" & $video_url_info[$i][0]
			Next
			GUICtrlSetData($quality_opt_combo, $k)
			GUICtrlSetState($dl_sub_button, 64)

			#cs
			grep quality (1quality2quality3.....) (take 2 to 0)
			from 2 to 0 grep url (quality2.....url2...) (take 2)


			;parser debug
			ConsoleWrite("grep quality" & @CRLF)
			For $i = 2 To $video_info_parsing[0]
				ConsoleWrite($video_info_parsing[$i] & @CRLF)
			Next


			For $i = 2 To $video_info_parsing[0]
				$video_url_temp[$i] = StringSplit($video_info_parsing[$i], "url", 1)
				If UBound($video_url_temp[$i]) < 3 Then
					;MsgBox(8240, "訊息", "影片地址讀取異常，可能導致下載失敗，請重試(" & $i & ")")
					ConsoleWrite("[error] Invalid response. No url detected." & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If StringInStr(($video_url_temp[$i])[2], "googlevideo.com") = 0 Then
					;MsgBox(8240, "訊息", "影片地址讀取異常，伺服器回傳非影片的結果，請重試(" & $i & ")")
					ConsoleWrite("[error] Garbage in response. " & ($video_url_temp[$i])[2] & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If StringInStr(($video_url_temp[$i])[2], "mime%253Daudio") <> 0 Then
					;MsgBox(8240, "訊息", "影片地址讀取異常，伺服器回傳無效地址，請重試(" & $i & ")")
					ConsoleWrite("[error] Invalid response. " & ($video_url_temp[$i])[2] & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
			Next

			;parser debug
			#cs
			ConsoleWrite("grep url" & @CRLF)
			For $i = 2 To $video_info_parsing[0]
				ConsoleWrite(($video_url_temp[$i])[2] & @CRLF)
			Next
			#ce


			;strip rubbish
			ConsoleWrite("[message] Parsing response." & @CRLF)
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[2]
				If UBound(StringSplit($j, "%3D", 1)) >= 3 Then
					$j = (StringSplit($j, "%3D", 1))[2]
				Else
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(3d)")
					ConsoleWrite("[error] Parsing error. Retrying. (3d)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If UBound(StringSplit($j, "%2C", 1)) >= 2 Then
					$j = (StringSplit($j, "%2C", 1))[1]
				Else
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(2c)")
					ConsoleWrite("[error] Parsing error. Retrying. (2c)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				If UBound(StringSplit($j, "%26", 1)) >= 2 Then
					$j = (StringSplit($j, "%26", 1))[1]
				Else
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(26)")
					ConsoleWrite("[error] Parsing Error. Retrying. (26)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				$j = _URLDec($j, 4)
				$j = _URLDec($j, 4)
				$k = _URLDec($j, 4)
				$k = _URLDec($k, 4)
				$k = _URLDec($k, 4)
				If StringInStr($j, "http") <> 1 Then
					;MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(3d)")
					ConsoleWrite("[error] Parsing Error. Retrying. (3d)" & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
				;if signature is not available, search for s instead
				If StringInStr($j, "signature") = 0 Then
					;The only way to tell that the signature is ciphered, is if the URLs in the map contain "s=" instead of "sig=".
					;MsgBox(8240, "訊息", "影片金鑰讀取失敗，請重試(sign)")
					;ConsoleWrite("error" & @CRLF)
					;FileDelete($get_video_info)
					;Return
					;get signature
					If StringInStr(($video_url_temp[$i])[1], "s%3D") <> 0 Then
						$l = 1
						$j = ($video_url_temp[$i])[1]
						$j = StringMid($j, StringInStr($j, "%26s%3D"))
						;$j = StringMid($j, StringInStr($j, "itag%253D"))
						$j = StringReplace($j, "%26s%3D", "")
						$j = (StringSplit($j, "%26", 1))[1]
						;$j = (StringSplit($j, "26", 1))[1]
						;$j = (StringSplit($j, "%2C", 1))[1]
						;$j = (StringSplit($j, "&", 1))[1]
						;$video_url_info[$i][0] = $video_url_info[$i][0] & " itag=" & $j
						If $j = "" Then
							;MsgBox(8240, "訊息", "影片金鑰讀取失敗，請重試或嘗試使用方法二破解(sig)")
							ConsoleWrite("[error] Failed to obtain signature. Retrying." & @CRLF)
							FileDelete($thumbnailfile)
							FileDelete($get_video_info)
							Return
						EndIf

						;use online decipher service??? or shall i implement it by myself
						$j = _SigDec($j)


						ConsoleWrite("[message] Decrypted Signature: " & $j & @CRLF)
						$k = $k & "&signature=" & $j
					Else
						;MsgBox(8240, "訊息", "影片金鑰讀取失敗，請重試(s)")
						ConsoleWrite("[error] Failed to obtain ciphered signature. Retrying." & @CRLF)
						FileDelete($thumbnailfile)
						FileDelete($get_video_info)
						Return
					EndIf
				EndIf


				$k = $k & "&title=" & $encodedtitle
				$video_url_info[$i][1] = $k
				ConsoleWrite("[message] Video url obtained. " & $video_url_info[$i][1] & @CRLF)
				ConsoleWrite("[message] Checking url validity. " & @CRLF)
				$m = InetGetSize ( $video_url_info[$i][1], 1)
				If $m = 0 Then
					ConsoleWrite("[message] Invalid url detected. Refetching. " & @CRLF)
					FileDelete($thumbnailfile)
					FileDelete($get_video_info)
					Return
				EndIf
			Next
			If $l = 1 Then
				;MsgBox(8240, "訊息", "請注意，已取得影片地址，由於本影片有加密，無法下載(sign)")
				ConsoleWrite("[message] Signature deciphered." & @CRLF)
			EndIf

			;get video resolution(p)
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[1]
				$j = (StringSplit($j, "%3D", 1))[2]
				$j = (StringSplit($j, "%26", 1))[1]
				$j = (StringSplit($j, "%2C", 1))[1]
				$j = (StringSplit($j, "&", 1))[1]
				$video_url_info[$i][0] = $j
				;ConsoleWrite($video_url_info[$i][0] & @CRLF)
			Next
			;get mime
			For $i = 2 To $video_info_parsing[0]
				If StringInStr($video_url_info[$i][1], "mime=") <> 0 Then
					$j = (StringSplit($video_url_info[$i][1], "mime=", 1))[2]
					$j = (StringSplit($j, "&", 1))[1]
					$video_url_info[$i][0] = $video_url_info[$i][0] & " (" & $j & ")"
					;ConsoleWrite($video_url_info[$i][0] & @CRLF)
				EndIf
			Next
			;get video itag value
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[2]
				$j = StringMid($j, StringInStr($j, "itag"))
				$j = StringMid($j, StringInStr($j, "itag%253D"))
				$j = StringReplace($j, "itag%253D", "")
				$j = (StringSplit($j, "%", 1))[1]
				;$j = (StringSplit($j, "26", 1))[1]
				;$j = (StringSplit($j, "%2C", 1))[1]
				;$j = (StringSplit($j, "&", 1))[1]
				$video_url_info[$i][0] = $video_url_info[$i][0] & " itag=" & $j
				ConsoleWrite("[message] Video mime type obtained. " & $video_url_info[$i][0] & @CRLF)
			Next

			GUICtrlSetState($watch_button, 64)
			GUICtrlSetState($download_button, 64)
			GUICtrlSetState($opt_mux, 64)
			GUICtrlSetState($quality_opt_combo, 64)
			$k = ""
			For $i = 2 To $video_info_parsing[0]
				$k = $k & "|" & $video_url_info[$i][0]
			Next
			GUICtrlSetData($quality_opt_combo, $k)
			#cs
			itag%253D
			itag%25252C

			mp4影音部分很安定，影音部分會亂跑
			檢查144p itag必須=160，不合報錯

			#ce

			#cs
			For $i = 2 To $video_info_parsing[0]
				$j = ($video_url_temp[$i])[2]
				$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = _URLDec($j, 4)
				;$j = $j & "title=" & $encodedtitle
				;$j =
				#cs
				$j = StringReplace($j, "&itag", "&itag")
				If @extended > 1 Then
					$k = (StringSplit($j, "&itag=", 1))[2]
					$k = (StringSplit($k, "&", 1))[1]
					ConsoleWrite($k & @CRLF)
					$j = StringReplace($j, "&itag=$k", "")
				EndIf

				$j = StringReplace($j, "&itag", "&itag")
				If @extended > 1 Then
					$k = (StringSplit($j, "&itag=", 1))[2]
					$k = (StringSplit($k, "&", 1))[1]
					ConsoleWrite($k & @CRLF)
					$j = StringReplace($j, "&itag=$k", "")
				EndIf
				#ce

				;If StringInStr($j, ",', 0, -1) <> 0 Then
				;	If

				If StringInStr($j, "=http") <> 1 Then
					MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(3d)")
					ConsoleWrite("error" & @CRLF)
					FileDelete($get_video_info)
					Return
				EndIf
				If StringInStr($j, "%2Fr") = 0 Then
					MsgBox(8240, "訊息", "影片地址讀取失敗，請重試(2Fr)")
					ConsoleWrite("error" & @CRLF)
					FileDelete($get_video_info)
					Return
				EndIf

				ConsoleWrite($j & @CRLF)
			Next
			#ce
			#ce
		EndIf
	Else
		MsgBox(8240, "訊息", "影片資訊讀取失敗，請重試")
		If StringInStr($video_info, "reason") <> 0 Then
			$j = (StringSplit($video_info, "reason=", 1))[2]
			$j = (StringSplit($j, "&", 1))[1]
			$k = _URLDec($j, 4)
			MsgBox(8240, "訊息", "錯誤原因: " & $k)
			ConsoleWrite("[error]" & " reason: " & $k & @CRLF)
		EndIf
		ConsoleWrite("[error] Failed to retrieve get_video_info dictionary. Please retry." & @CRLF)
		FileDelete($thumbnailfile)
		FileDelete($get_video_info)
		$fetch = 0
		Return
	EndIf

	;delete get_video_info temp file
	$fetch = 0
	FileDelete($get_video_info)

	;get video thumbnail
	$thumbnailfile = _WinAPI_GetTempFileName(@TempDir)
	InetGet("http://img.youtube.com/vi/" & $video_id & "/mqdefault.jpg", $thumbnailfile, $INET_FORCERELOAD, $INET_DOWNLOADWAIT)
	GUICtrlSetImage($F1Image1, $thumbnailfile)

	ConsoleWrite("[message] Video thumbnail retrieved." & @CRLF)
	ConsoleWrite("[message] Fetching complete." & @CRLF)






	;http://www.youtube.com/get_video_info?eurl=http%3A%2F%2Fkej.tw%2F&sts=17015&video_id=Phzkeu3v130
    ;https://youtu.be/MvKywBZcIVo

	;find sts value from www.youtube.com/embed/ id

	;create an instance of browser for html parsing
	;$videoIE = _IECreate


	;if url parsed -> activate quality selector & download button
	;if "mux video" option selected -> show warning info (the video downloaded is without audio)
EndFunc

;fetch video loop
Func _Fetch()
	GUICtrlSetState($retrieve_button, 128)
	GUICtrlSetData($retrieve_button, "請稍候")
	$fetch = 1
	While 1
		If $fetch = 0 Then
			ExitLoop
		EndIf
		_FetchVideoInfo()
	WEnd
	GUICtrlSetState($retrieve_button, 64)
	GUICtrlSetData($retrieve_button, "獲取資訊")
EndFunc

;decipher signature
Func _SigDec($sig)
	Local $s
	Local $decs
	Local $pid
	Local $command
	Local $playerver
	Local $video_page
	Local $video_page_file

	$s = $sig

	;get player version from video page
	$video_page_file = _WinAPI_GetTempFileName(@TempDir)
	InetGet("https://www.youtube.com/watch?v=" & $video_id, $video_page_file, $INET_FORCERELOAD, $INET_DOWNLOADWAIT)
	$video_page = FileRead($video_page_file)
	If StringInStr($video_page, "\/jsbin\/player-") <> 0 Then
		$video_page = (StringSplit($video_page, "\/jsbin\/player-", 1))[2]
		$video_page = (StringSplit($video_page, ".js", 1))[1]
		$video_page = StringReplace($video_page, "\", "")
		$playerver = $video_page
	Else
		ConsoleWrite("[error] Could not get player verion." & @CRLF)
		Return ""
	EndIf
	FileDelete($video_page_file)


	;$playerver = " en_US-vflduS31F/base"

	ConsoleWrite("[decipher] Running external decipherer." & @CRLF)
	ConsoleWrite("[decipher] Player version: " & $playerver & ".js" & @CRLF)

	$command = @WorkingDir & "\lib\decipher.exe " & $s & " " & $playerver
	$pid = Run('"' & @ComSpec & '" /c ' & $command, '', @SW_HIDE, 2 + 4)

	While 1
        $decs &= StdoutRead($pid, False, False)
        If @error Then
			ExitLoop
		EndIf
        Sleep(10)
    WEnd

	$decs = StringStripCR($decs)
	$decs = StringStripWS($decs, 7)

	ConsoleWrite("[decipher] Signature: " & $decs & @CRLF)
	Return $decs
	;MsgBox(0, "", $decs)
	;parse video page


	#cs

	find player js url(parse video page instead of video info)
	find ("signature", xxxxxx(


	#ce


EndFunc



;downloader function, pass the url to an external downloader due to lack of multi-threading in autoit
Func _Download()
	Local $selected_quality
	Local $mux_or_not
	Local $downloadlinktemp
	Local $downloadlinktemp_file
	Local $filesize
	Local $muxmessage

	Local $command
	Local $pid

	Local $i
	Local $j
	Local $k

	$selected_quality = GUICtrlRead($quality_opt_combo)
	For $i = 2 To $format_count
		If $selected_quality = $video_url_info[$i][0] Then
			$selected_quality = $i
		EndIf
	Next
	If $selected_quality <> "" Then
		$i = GUICtrlRead($opt_mux)
		If $i = $GUI_CHECKED Then
			$mux_or_not = 1
			$muxmessage = "是"
		ElseIf $i = $GUI_UNCHECKED Then
			$mux_or_not = 0
			$muxmessage = "否"
		Else
			$mux_or_not = -1
			Return
		EndIf

		If (StringInStr($video_url_info[$selected_quality][0], "p ") = 0 Or StringInStr($video_url_info[$selected_quality][0], "mp4") = 0) And $mux_or_not = 1 Then
			MsgBox(8240, "訊息", "影音封裝僅支援mp4格式，請另選擇")
			Return
		EndIf


		$filesize = InetGetSize ( $video_url_info[$selected_quality][1], 1)

		InputBox("訊息", "影片位址已取得，請複製或按確定開始下載" & @CRLF & @CRLF & "檔案類型: " & $video_url_info[$selected_quality][0] & @CRLF & "檔案大小: " & Round(($filesize / 1024), 3) & " KiB" & @CRLF & "下載後是否封裝音軌: " & $muxmessage, $video_url_info[$selected_quality][1], "", 300)
		If @error = 1 Then
			Return
		EndIf
		If $save_location_selector = "" Then
			MsgBox(8240, "訊息", "請選擇存檔路徑")
			Return
		EndIf

		;autoit does not support threading, use external file instead
		$downloadlinktemp = _WinAPI_GetTempFileName(@TempDir)
		$downloadlinktemp_file = FileOpen($downloadlinktemp, 1)
		FileWriteLine($downloadlinktemp_file, $video_url_info[$selected_quality][1]) ;video url
		FileWriteLine($downloadlinktemp_file, $mux_or_not) ;to mux or not
		FileWriteLine($downloadlinktemp_file, $downloadlinktemp) ;temp file location(to delete after download)
		FileWriteLine($downloadlinktemp_file, $save_location_selector) ;file saving location
		FileWriteLine($downloadlinktemp_file, $title)
		FileWriteLine($downloadlinktemp_file, $video_url_info[$selected_quality][0])
		If $mux_or_not = 1 Then
			FileWriteLine($downloadlinktemp_file, $m4a_url)
		EndIf
		FileClose($downloadlinktemp_file)

		$command = @WorkingDir & "\lib\downloader.exe " & $downloadlinktemp
		;$pid = Run('"' & @ComSpec & '" /c ' & $command, '', @SW_HIDE, 2 + 4)
		$pid = Run($command, '', @SW_SHOW, 2 + 4)

		Return
	Else
		MsgBox(8240, "訊息", "請選擇影片品質")
		Return
	EndIf
	;MsgBox(0, "debug", $selected_quality)
EndFunc

Func _DownloadM4a()
	Local $selected_quality
	Local $mux_or_not
	Local $downloadlinktemp
	Local $downloadlinktemp_file
	Local $filesize
	Local $muxmessage
	Local $command
	Local $pid

	Local $i

	$filesize = InetGetSize ( $m4a_url, 1)

	InputBox("訊息", "音訊位址已取得，請複製或按確定開始下載" & @CRLF & @CRLF & "檔案類型: " & "audio/mp4; codecs=mp4a" & @CRLF & "檔案大小: " & Round(($filesize / 1024), 3) & " KiB" & @CRLF, $m4a_url, "", 300)
	If @error = 1 Then
		Return
	EndIf
	If $save_location_selector = "" Then
		MsgBox(8240, "訊息", "請選擇存檔路徑")
		Return
	EndIf
		;autoit does not support threading, use external file instead
	$downloadlinktemp = _WinAPI_GetTempFileName(@TempDir)
	$downloadlinktemp_file = FileOpen($downloadlinktemp, 1)
	FileWriteLine($downloadlinktemp_file, $m4a_url) ;video url
	FileWriteLine($downloadlinktemp_file, "0") ;to mux or not
	FileWriteLine($downloadlinktemp_file, $downloadlinktemp) ;temp file location(to delete after download)
	FileWriteLine($downloadlinktemp_file, $save_location_selector) ;file saving location
	FileWriteLine($downloadlinktemp_file, $title)
	FileWriteLine($downloadlinktemp_file, "m4a")
	FileClose($downloadlinktemp_file)

	$command = @WorkingDir & "\lib\downloader.exe " & $downloadlinktemp
	;$pid = Run('"' & @ComSpec & '" /c ' & $command, '', @SW_HIDE, 2 + 4)
	$pid = Run($command, '', @SW_SHOW, 2 + 4)

	Return
EndFunc

Func _DownloadOga()
	Local $selected_quality
	Local $mux_or_not
	Local $downloadlinktemp
	Local $downloadlinktemp_file
	Local $filesize
	Local $muxmessage
	Local $command
	Local $pid

	Local $i

	$filesize = InetGetSize ( $oga_url, 1)

	InputBox("訊息", "音訊位址已取得，請複製或按確定開始下載" & @CRLF & @CRLF & "檔案類型: " & "audio/webm; codecs=vorbis" & @CRLF & "檔案大小: " & Round(($filesize / 1024), 3) & " KiB" & @CRLF, $oga_url, "", 300)
	If @error = 1 Then
		Return
	EndIf
	If $save_location_selector = "" Then
		MsgBox(8240, "訊息", "請選擇存檔路徑")
		Return
	EndIf

	;autoit does not support threading, use external file instead
	$downloadlinktemp = _WinAPI_GetTempFileName(@TempDir)
	$downloadlinktemp_file = FileOpen($downloadlinktemp, 1)
	FileWriteLine($downloadlinktemp_file, $oga_url) ;video url
	FileWriteLine($downloadlinktemp_file, "0") ;to mux or not
	FileWriteLine($downloadlinktemp_file, $downloadlinktemp) ;temp file location(to delete after download)
	FileWriteLine($downloadlinktemp_file, $save_location_selector) ;file saving location
	FileWriteLine($downloadlinktemp_file, $title)
	FileWriteLine($downloadlinktemp_file, "oga")
	FileClose($downloadlinktemp_file)

	$command = @WorkingDir & "\lib\downloader.exe " & $downloadlinktemp
	;$pid = Run('"' & @ComSpec & '" /c ' & $command, '', @SW_HIDE, 2 + 4)
	$pid = Run($command, '', @SW_SHOW, 2 + 4)

	Return
EndFunc



;watch online
Func _Watch()
	Local $selected_quality

	$selected_quality = GUICtrlRead($quality_opt_combo)
	For $i = 2 To $video_info_parsing[0]
		If $selected_quality = $video_url_info[$i][0] Then
			$selected_quality = $i
		EndIf
	Next
	If $selected_quality <> "" Then
		ShellExecute($video_url_info[$selected_quality][1])
	Else
		MsgBox(8240, "訊息", "請選擇影片品質")
		Return
	EndIf
EndFunc


;path selector
Func _SelectPath()
	GUISetState(@SW_DISABLE, $Form1)
	$save_location_selector = FileSelectFolder("選擇存檔位置", "", "", "", $Form1)
	GUISetState(@SW_ENABLE, $Form1)
	GUISetState(@SW_SHOW, $Form1)
	GUICtrlSetState($save_location, 256)
	GUICtrlSetData($save_location, $save_location_selector)
EndFunc


;close
Func _Close()
	If @GUI_WinHandle = $Form2 Then
		;destroy about box and return to the main window
		GUIDelete($Form2)
		GUISetState(@SW_ENABLE, $Form1)
		WinActivate($Form1)
		;GUISetState(@SW_SHOWNORMAL, $Form1)
		GUICtrlSetState($video_url_box, 256)
	ElseIf @GUI_WinHandle = $Form1 Then
		FileDelete($thumbnailfile)
		Exit
	EndIf
EndFunc


;download subtitle(under development)
Func _DlSubtitle()
	;MsgBox(8240, "無此功能", "此功能尚在開發中！" & @CRLF & "點擊確定打開在線字幕下載網站")
	;ShellExecute("http://mo.dbxdb.com/")
	Local $ie
	Local $url

	#cs
	If $save_location_selector = "" Then
		MsgBox(8240, "訊息", "請選擇存檔路徑")
		Return
	EndIf
	#ce

	$url = "http://mo.dbxdb.com/mo.php?lang=en&url=https%3A//www.y%60%60%60be.com/watch%3Fv%3D" & $video_id
	$ie = _IECreate("about:blank")
	_IENavigate($ie, "http://mo.dbxdb.com/")
	_IENavigate($ie, $url)

	Do
		If WinActive("[Class:IEFrame]") Then
			Local $hIE = WinGetHandle("[Class:IEFrame]")
			Local $hCtrl = ControlGetHandle($hIE, "", "[ClassNN:DirectUIHWND1]")
			Local $aPos = ControlGetPos($hIE, "", $hCtrl)
			Local $aWinPos = WinGetPos($hIE)
			If ControlCommand($hIE, "", $hCtrl, "IsVisible") AND $aPos[1] > .75 * $aWinPos[3] Then ; Check if the control is in the bottom 25% of the page.
				ControlClick($hIE, "", $hCtrl, "primary", 1, $aPos[2] - 160, $aPos[3] - 30)
				Sleep(500)
				ControlSend($hIE, "", $hCtrl, "{down}{down}{enter}")
				ExitLoop
			EndIf
		EndIf
		sleep(100)
	Until WinExists("Save As") Or WinActive("[Class:IEFrame]") = False




	;_InetGetEX("http://mo.dbxdb.com/mo.php?lang=en&url=https%3A//www.y%60%60%60be.com/watch%3Fv%3D" & $video_id, $save_location_selector & "\" & $video_id & ".zip", True, Default, "http://mo.dbxdb.com/")

	;MsgBox(8240, "訊息", "字幕壓縮檔已經下載")
EndFunc


;about box
Func _About()
	GUISetState(@SW_DISABLE, $Form1)
	Local $F2GroupBox1
	Local $F2Image1
	Local $F2Label1
	Local $F2Label2
	Local $F2Label3
	Local $F2Label4
	Local $F2Button1
	$Form2 = GUICreate("關於", 320, 259, 463, 552)
	$F2GroupBox1 = GUICtrlCreateGroup("", 8, 8, 305, 201)
	$F2Image1 = GUICtrlCreatePic(".\logo.bin", 16, 22, 100, 100)
	$F2Label1 = GUICtrlCreateLabel("Youtube HD 下載工具", 152, 24, 114, 17)
	$F2Label2 = GUICtrlCreateLabel("Version 0.1b 測試版", 152, 48, 102, 17)
	$F2Label4 = GUICtrlCreateLabel("本軟體僅為學術研究及網路速度測試使用，測試過程產" & @CRLF & "生的任何檔案也僅作為電腦硬體效能測試，並請於24小" & @CRLF & "時內刪除。", 16, 160, 292, 42)
	$F2Label3 = GUICtrlCreateLabel("Copyright " & ChrW(169) & " 2016 hpbox", 16, 136, 160, 17)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$F2Button1 = GUICtrlCreateButton("確定", 124, 224, 75, 25, 0)

	GUICtrlSetOnEvent($F2Button1, "_Close")
	GUISetOnEvent($GUI_EVENT_CLOSE, "_Close")

	GUISetState(@SW_SHOW)
EndFunc


;main window
Func _Main()
	Local $F1Label1
	Local $F1Label2
	Local $F1Label3
	Local $F1Label4
	Local $F1Label5
	Local $F1Label6
	Local $F1Label7
	Local $F1Label11

	$Form1 = GUICreate("Youtube HD 下載工具", 518, 275, 271, 380)
	$F1Label1 = GUICtrlCreateLabel("影片地址:", 16, 20, 55, 17)
	$video_url_box = GUICtrlCreateInput("", 80, 16, 337, 21)
	$retrieve_button = GUICtrlCreateButton("獲取資訊", 432, 14, 73, 25)
	$F1Label2 = GUICtrlCreateLabel("儲存位置:", 16, 52, 55, 17)
	$save_location = GUICtrlCreateInput("", 80, 48, 337, 21)
	$browser_button = GUICtrlCreateButton("瀏覽", 432, 46, 73, 25)
	;$F1Group1 = GUICtrlCreateGroup("選項", 280, 80, 225, 110)
	$opt_mux = GUICtrlCreateCheckbox("將影音封裝為一個檔案", 368, 78, 153, 25)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$quality_opt_combo = GUICtrlCreateCombo("", 80, 80, 270, 25, BitOR($CBS_DROPDOWNLIST,$CBS_AUTOHSCROLL))
	$F1Label3 = GUICtrlCreateLabel("影片品質:", 16, 84, 55, 17)
	$F1Label4 = GUICtrlCreateLabel("影片資訊:", 16, 124, 55, 17)
	$F1Image1 = GUICtrlCreatePic("", 80, 115, 160, 90)
	$F1Label5 = GUICtrlCreateLabel("標題:", 250, 115, 55, 17)
	$F1Label8 = GUICtrlCreateLabel("", 250, 128, 255, 40, $SS_NOPREFIX)
	$F1Label6 = GUICtrlCreateLabel("上傳者:", 250, 172, 55, 17)
	$F1Label9 = GUICtrlCreateLabel("", 298, 172, 207, 17, $SS_NOPREFIX)
	$F1Label7 = GUICtrlCreateLabel("總長度:", 250, 190, 55, 17)
	$F1Label10 = GUICtrlCreateLabel("", 298, 190, 90, 17)
	$F1Label11 = GUICtrlCreateLabel("抓取方法:", 16, 209, 55, 17)
	$F1Radio1 = GUICtrlCreateRadio("方法1", 80, 208, 55, 16)
	$F1Radio2 = GUICtrlCreateRadio("方法2", 150, 208, 55, 16)

	$download_button = GUICtrlCreateButton("下載選擇的影片品質", 256, 235, 160, 25)
	$watch_button = GUICtrlCreateButton("觀賞", 256, 207, 160, 25)
	$dl_m4a_button = GUICtrlCreateButton("下載音訊(m4a)", 16, 235, 113, 25)
	$dl_oga_button = GUICtrlCreateButton("下載音訊(oga)", 136, 235, 105, 25)
	$dl_sub_button = GUICtrlCreateButton("下載字幕", 432, 235, 73, 25)
	$about_button = GUICtrlCreateButton("關於", 432, 207, 73, 25)

	;gui events
	GUICtrlSetOnEvent($retrieve_button, "_Fetch")
	GUICtrlSetOnEvent($browser_button, "_SelectPath")
	GUICtrlSetOnEvent($dl_m4a_button, "_DownloadM4a")
	GUICtrlSetOnEvent($dl_oga_button, "_DownloadOga")
	GUICtrlSetOnEvent($dl_sub_button, "_DlSubtitle")
	GUICtrlSetOnEvent($download_button, "_Download")
	GUICtrlSetOnEvent($watch_button, "_watch")
	;GUICtrlSetOnEvent($copy_download_link,
	GUICtrlSetOnEvent($about_button, "_About")
	GUISetOnEvent($GUI_EVENT_CLOSE, "_Close")

	;download buttons will be activated after the program fetches video info
	GUICtrlSetState($F1Radio1, 1)
	;GUICtrlSetState($F1Radio2, 128)
	GUICtrlSetState($quality_opt_combo, 128)
	GUICtrlSetState($opt_mux, 128)
	GUICtrlSetState($dl_m4a_button, 128)
	GUICtrlSetState($dl_oga_button, 128)
	GUICtrlSetState($dl_sub_button, 128)
	GUICtrlSetState($download_button, 128)
	GUICtrlSetState($watch_button, 128)

	GUICtrlSetState($video_url, 256)

	GUICtrlSetTip($opt_mux, "下載完後，自動在mp4檔案加上m4a音軌。")

	;show Form1
	GUISetState(@SW_SHOW)
EndFunc