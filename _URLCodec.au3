#include-once
#include <array.au3>

Func _URLDec($URL_str, $Encode = 1)
        ;afan 提示：转换经ANSI(GB2312)URL编码后的字符串为原始字符串
        ;$URL_str - URL编码字符串
        ;$Encode - URL编码格式 ;1 (默认) = ANSI ;2 = UTF16 小 ;3 = UTF16 大 ;4 = UTF8
        ;返回值：成功 - 返回编码字符串的原始字符串； 失败 - 返回原字符串并设置 @Error = 1

        Local $Rstr, $aSR, $str_Tmp, $i
        $Rstr = StringReplace($URL_str, '+', ' ')
        $aSR = StringRegExp($Rstr, '(?:%\w{2})+', 3)
        If @error Then Return SetError(1, 0, $Rstr)
        For $i = 0 To UBound($aSR) - 1
                $str_Tmp = BinaryToString('0x' & StringReplace($aSR[$i], '%', ''), $Encode)
                $Rstr = StringReplace($Rstr, $aSR[$i], $str_Tmp, 1)
        Next
        Return $Rstr
EndFunc   ;==>_URLEncodeToString