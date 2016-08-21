;================================================================================
; Function Name....: _INetGetEx
; Description......: Download a file from the net
; Syntax...........: _INetGetEx($sURL, $sFile[, $fOverWriteCreate = Default[, $sUserAgent = Default[, $sReferrer = Default]]])
; Parameter(s).....: $sURL - The URL of the file to download
;                    $sFile - The local path to save the file to
;                    $fOverWriteCreate - Set to True to overwrite existing file
;                    $sUserAgent - The User-Agent (http://en.wikipedia.org/wiki/User_agent)
;                    $sReferrer - The Referrer (http://en.wikipedia.org/wiki/Referrer)
; Return Value(s)..: Success: 1
;                    Failure: 0 ; sets @error to non-zero and @extended to the returned HTTP Status
;                     @error = 1: $fOverWriteCreate is False and file already exists
;                     @error = 2: Somethng went wrong with the download
; Requirement(s)...: -
; Related..........: -
; Limitation(s)....: -
; Example(s).......: -
; Comment(s).......: http://www.paulsadowski.com/WSH/getremotebinaryfile.htm
; Author(s)........: Robjong
; Modified.........: -
;================================================================================
Func _INetGetEx($sURL, $sFile, $fOverWriteCreate = Default, $sUserAgent = Default, $sReferrer = Default)
;~  Local $adTypeBinary = 1, $adSaveCreateNotExist = 1, $adSaveCreateOverWrite = 2
    Local $iSaveCreateOverWrite = 1
    If $fOverWriteCreate Then $iSaveCreateOverWrite = 2
    If $fOverWriteCreate <> 2 And FileExists($sFile) Then Return SetError(1, 0, 0)
    If Not $sUserAgent Or $sUserAgent <= -1 Or $sUserAgent == Default Then $sUserAgent = "AutoIt3Script" ; AutoIt
    If Not $sReferrer Or $sReferrer <= -1 Or $sReferrer == Default Then $sReferrer = ""

    Local $oHTTP = ObjCreate('WinHTTP.WinHTTPRequest.5.1')
    $oHTTP.Open('GET', $sURL, False)
    If $sUserAgent Then $oHTTP.SetRequestHeader("User-Agent", $sUserAgent)
    If $sReferrer Then $oHTTP.SetRequestHeader("Referrer", $sReferrer)
    $oHTTP.Send()

    Local $oBinaryStream
    If $oHTTP.Status == 200 Then ; 200 = OK
        $oBinaryStream = ObjCreate("ADODB.Stream")
        $oBinaryStream.Type = 1
        $oBinaryStream.Open
        $oBinaryStream.Write($oHTTP.ResponseBody)
        $oBinaryStream.SaveToFile($sFile, Int($iSaveCreateOverWrite))
        $oBinaryStream.Close
        Return SetError(0, 0, 1)
    EndIf

    $oBinaryStream.Close
    Return SetError(1, $oHTTP.Status, 0)
EndFunc   ;==>_INetGetEx