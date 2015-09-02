#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=edit_ffcfg.exe
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=Programm zur Anpassung der firefox.cfg
#AutoIt3Wrapper_Res_Description=Editiere firefox.cfg
#AutoIt3Wrapper_Res_Fileversion=1.0.0.15
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_LegalCopyright=Holger Pandel, 2015
#AutoIt3Wrapper_Res_Language=1031
#AutoIt3Wrapper_Run_Tidy=n
#Tidy_Parameters=/gd
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs
0) General INI format description:
**********************************

	[general]
	ff_cfg = <path to firefox auto-configuration file>

	[single_parameter]
	count = <number of parameters that follow>
	param1 = <first parameter to be added, deleted or changed>
	param2 = <second parameter to be added, deleted or changed>
	....

	[capability_policies]
	count = <number of policies that follow>
	policy1 = <first policy to be added, deleted or changed>
	policy2 = <second policy to be added, deleted or changed>


I) Single_parameter entry format:
*********************************

A parameter has to be written in the following format:

	<preference type>|<parameter name>|<parameter value>

	<preference type> is one of values: pref, lockPref, defaultPref, user_pref
	<parameter name> is the exact name, ie. "auto.update.enabled", "social.active", BUT WITHOUT QUOTES
	<parameter value> value of parameter, only use quotes if these are part of the value

All values have to be separated by a single | symbol.

	a) Adding/Editing parameters:
	-----------------------------

	Example:
		param1=pref|pref.advanced.javascript.disable_button.advanced|false
		param2=lockPref|plugins.hide_infobar_for_outdated_plugin|True

	Resulting configuration lines:
		pref("pref.advanced.javascript.disable_button.advanced", false);
		lockPref("plugins.hide_infobar_for_outdated_plugin", false);

	b) Removing a parameter:
	-------------------------

	If you specify only the first two values and end the second parameter with a | symbol, the parameter will be removed from the file.

		param<n>=<preference type>|<parameter name>|

	Example:
		param1=pref|auto.update.enable|

	would remove the line

		pref("auto.update.enable", ...);

	completely.


II) Capability_policies entry format:
*************************************

A policy has to be written in the following format:

	<preference type>|<policy name>|<sites value>[|<policy.parameter name>|<policy.parameter value>][|<policy.parameter name>|<policy.parameter value>]....

Mandatory values:

	<preference type> is one of values: pref, lockPref, defaultPref, user_pref
	<policy name> policy name, ie. "my_policy", BUT WITHOUT QUOTES
	<sites value> site to apply this policy to, ie. "http://my.server.local", "http://my.server.local:4646"

Optional values (multiple parameter<->value pairs possible):

	<policy.parameter name> parameter name for this policy
	<policy.parameter value> parameter value for this policy

All values have to be separated by a single | symbol.

	a) Adding/Editing policies:
	---------------------------

	Example:
		policy1=pref|our_links|"http://server.local.net"|checkloaduri.enabled|"allAccess"
		policy2=pref|more_of_our_links|"http://server2.local.net:4646"|checkloaduri.enabled|"allAccess"|Clipboard.cutcopy|"allAccess"|Clipboard.paste|"allAccess"

	Resulting configuration lines
		pref("capability.policy.policynames", "our_links,more_of_our_links");
		pref("capability.policy.our_links.sites", "http://server.local.net");
		pref("capability.policy.our_links.checkloaduri.enabled", "allAccess");
		pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");
		pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");
		pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");
		pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");

	b) Removing policies:
	---------------------

	If you specify only the first two values and end the second parameter with a | symbol, the policy will be completely removed from the file.

		<preference type>|<policy name>|

	Let's take the last example result as an existing configuration. A policy line like

		policy1=pref|our_links|

	would result in the following change:

		pref("capability.policy.policynames", "more_of_our_links");
		pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");
		pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");
		pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");
		pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");

	c) Regarding already existing policies not mentioned in the INI file:
	---------------------------------------------------------------------

	Already existing policies, which are not mentioned in the INI file, will be simply retained.

	Let's assume you already had the following policy lines in your auto-configuration file:

		pref("capability.policy.policynames", "alreadytheir,more_of_our_links");
		pref("capability.policy.alreadytheir", "http://server.local.net");
		pref("capability.policy.alreadytheir", "allAccess");
		pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");
		pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");
		pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");
		pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");

	If you now apply the following rules

		policy1=pref|our_links|"http://server.local.net"|checkloaduri.enabled|"allAccess"
		policy2=pref|more_of_our_links|

	the result would be:

		pref("capability.policy.policynames", "alreadytheir,our_links");
		pref("capability.policy.policynames", "alreadytheir");
		pref("capability.policy.alreadytheir", "http://server.local.net");
		pref("capability.policy.alreadytheir", "allAccess");
		pref("capability.policy.our_links.sites", "http://server.local.net");
		pref("capability.policy.our_links.checkloaduri.enabled", "allAccess");

#ce

; includes
#include <file.au3>
#include <array.au3>
#include <assoarrays.au3>
#include "GetOpt.au3"

;Opt('MustDeclareVars', 1)
; appplication title and version
Global $header = "edit_ffcfg (MIT licensed)"
Global $version = "1.0"
Global $logdir = @TempDir & "\edit_ffcfg"
Global $log_mode = False ; write log file = true
Global $log_file = $logdir & "\edit_ffcfg.log" ; set default logfile name

; if true, it outputs some messages
Global $debug = False
; if true, shows array with modified cfg data
Global $showmod = False
; if true, nothing will be changed, debugging enabled by default
Global $test = True
; if
Global $iniName = "edit_ffcfg"

; let's have a look at the CmdLine
If 0 <> $CmdLine[0] Then
	_getopts()
EndIf


; ---- MAIN ---------
_debug("Running as user: " & @UserName)
_debug("Profile dir: " & @UserProfileDir)
; Load ini data
_getIniValues($iniName)
;x_display()

Local $rawCfg = readFFCfg(x($iniName & ".general.ff_cfg"))
Local $arCfg = parseCfg($rawCfg)

; edit parameters
If x($iniName & ".single_parameter.count") > 0 Then $arCfg = editSingleParameter($arCfg)
If x($iniName & ".capability_policies.count") > 0 Then $arCfg = editCapabilityPolicies($arCfg)

If $showmod Then _ArrayDisplay($arCfg, "Changed configuration", "", 96)

; write configuration back to cfg file
If Not $test Then
	writeFFCfg(x($iniName & ".general.ff_cfg"), $arCfg)
Else
	_debug("edit_ffcfg Test mode - Program running in test mode. Nothing will be changed! See --help for details...")
	MsgBox(1, "edit_ffcfg Test mode", "Program running in test mode. Nothing will be changed! See --help for details...", 2)
EndIf

Exit 0

; ---------- subroutines ------------------------------------------------------------------------

Func _getLeaf($leaf, $tab)
	Local $str
	If not IsObj($leaf) Then Return
	$colKeys = $leaf.Keys
	For $strKey in $colKeys
		$str = ""
		If IsArray($leaf.Item($strKey)) Then		
			$str = $leaf.Item($strKey)[0]
			For $i = 1 to Ubound($leaf.Item($strKey)) - 1
				$str &= "|" & $leaf.Item($strKey)[$i]
			Next
			_debug($tab & $strKey & ' -> ' & $str)
		Else
			_debug($tab & $strKey & ' -> ' & $leaf.Item($strKey))
		EndIf
		_getLeaf($leaf.Item($strKey), $tab & "  ")
	Next				
EndFunc

; read INI file

Func _getIniValues($iniName)
	Dim $szDrive, $szDir, $szFName, $szExt, $pathTemp, $kdSel, $op
	$pathTemp = _PathSplit(@ScriptFullPath, $szDrive, $szDir, $szFName, $szExt)

	Dim $appPath = $szDrive & $szDir
	Dim $iniFile = $appPath & $iniName & ".ini"
	
	Dim $rc, $cpm[3], $msg, $str, $colKeys
	
	_debug("Getting INI values from: " & $iniFile)
	
	If FileExists($iniFile) Then ;--- global INI file found
		$rc = _ReadAssocFromIni2($iniFile)
		If @error Then
			_debug("Error while reading ini file. Errno: " & @error)
		Else
			_debug("Entries read: " & $rc)
			_debug("Logging configuration:")
			_debug("--------------- snip ------------------")
			_getLeaf($_xHashCollection, "  ")
			_debug("--------------- snip -----------------")
		EndIf
		
	ElseIf FileExists($appPath & "edit_ffcfg.ini") Then
		$msg = "You specified the following INI file to use:" & @CRLF & @CRLF & _
				$iniFile & @CRLF & @CRLF & _
				"This file is not available, but an existing edit_ffcfg.ini in the" & @CRLF & _
				"program directory was found. This file will not be overriden." & @CRLF & @CRLF & _
				"Please check your command line value."
		_debug($msg)
		MsgBox(0 + 64, "Missing configuration file", $msg, 5)
		Exit 1
	Else ;--- INI not existing, creating new one in script directory
		$msg = "You are going to use edit_ffcfg for the first time." & @CRLF & _
				"A new INI file with example values will be created in the script directory." & @CRLF & _
				"Please customize the INI file before using it."
		_debug($msg)
		MsgBox(0 + 64, "First Start", $msg, 5)
		
		x($iniName & ".general.ff_cfg", "C:\Program Files (x86)\Mozilla Firefox\firefox-example.cfg")
		
		x($iniName & ".single_parameter.count", 4)
		Local $a = ["pref", "example.mozilla.param1", '"value_for_param"']
		x($iniName & ".single_parameter.param1", $a)
		Local $a = ["lockPref", "another_example.mozilla.param", False]
		x($iniName & ".single_parameter.param2", $a)
		Local $a = ["defaultPref", "plugins.update.url", '""']
		x($iniName & ".single_parameter.param3", $a)
		Local $a = ["pref", "auto.update.enable-empty_third_value_means_remove_this_line", ""]
		x($iniName & ".single_parameter.param4", $a)

		x($iniName & ".capability_policies.count", 3)
		;format: type, policy name, sites, <param1 name>, <param1 value>, <param2 name>, <param2 value>, ...
		;if site is empty, policy will be deleted
		Local $a = ["pref", "our_links", '"http://server.local.net"', "checkloaduri.enabled", '"allAccess"']
		x($iniName & ".capability_policies.policy1", $a)
		Local $a = ["pref", "more_of_our_links", '"http://server2.local.net:4646"', "checkloaduri.enabled", '"allAccess"', "Clipboard.cutcopy", "allAccess", "Clipboard.paste", "allAccess"]
		x($iniName & ".capability_policies.policy2", $a)
		Local $a = ["pref", "old_policy-empty_third_value_means_remove_this_line", ""]
		x($iniName & ".capability_policies.policy3", $a)

		_WriteAssocToIni($iniName)

		Exit 0
		
	EndIf
	
EndFunc   ;==>_getIniValues


; read firefox auto-configuration file into 1D text array

Func readFFCfg($filename)
	Local $text[1], $rc

	_debug("Reading file: " & $filename)
	
	If FileExists($filename) Then
		_debug("Reading current configuration from: " & $filename)
		$rc = _FileReadToArray($filename, $text)
		If $rc = 0 Then
			_debug("Error reading file: " & $filename)
			Exit 1
		EndIf
	Else
		_debug("File not found: " & $filename)
		$text[0] = 0
	EndIf
	
	Return $text
EndFunc   ;==>readFFCfg

; write firefox auto-configuration file from array

Func writeFFCfg($filename, $array)
	Local $file = FileOpen($filename, 2); create/empty current configuration file
	
	If $file = -1 Then
		_debug("Error opening file for replacement: " & $filename)
		Exit 1
	EndIf

	_debug("Now writing new configuration to: " & $filename)

	For $i = 0 To UBound($array) - 1
		Select
			Case $array[$i][0] = "" Or $array[$i][0] = "remove"
				ContinueLoop
			Case $array[$i][0] = "comment"
				FileWriteLine($file, $array[$i][1])
			Case $array[$i][0] = "empty"
				FileWriteLine($file, "")
			Case Else
				FileWriteLine($file, $array[$i][0] & '("' & $array[$i][1] & '", ' & $array[$i][2] & ");")
		EndSelect
	Next
	
	FileClose($file)
EndFunc   ;==>writeFFCfg

; split 1D text array into real config param array
; line types: comment, empty, pref, lockPref, defaultPref, user_pref, remove(special)

Func parseCfg($cfg)
	Local $arCfg[1][4], $cpm

	_debug("Separating param<->value pairs...")

	If $cfg = "" Then Exit 1
	
	For $x = 1 To $cfg[0]
		ReDim $arCfg[UBound($arCfg) + 1][4]
		Select
			; comment line
			Case StringMid(StringStripWS($cfg[$x], 8), 1, 2) = "//"
				$arCfg[$x - 1][0] = "comment"
				$arCfg[$x - 1][1] = $cfg[$x]
				; empty line
			Case StringStripWS($cfg[$x], 8) = ""
				$arCfg[$x - 1][0] = "empty"
				$arCfg[$x - 1][1] = ""
				; "pref" line
			Case StringUpper(StringMid(StringStripWS($cfg[$x], 8), 1, 4)) = "PREF"
				$cpm = getConfigParamAndValue($cfg[$x], "pref")
				$arCfg[$x - 1][0] = "pref"
				$arCfg[$x - 1][1] = $cpm[0]
				$arCfg[$x - 1][2] = $cpm[1]
				; lockPref "line"
			Case StringUpper(StringMid(StringStripWS($cfg[$x], 8), 1, 8)) = "LOCKPREF"
				$cpm = getConfigParamAndValue($cfg[$x], "lockPref")
				$arCfg[$x - 1][0] = "lockPref"
				$arCfg[$x - 1][1] = $cpm[0]
				$arCfg[$x - 1][2] = $cpm[1]
				; "defaultPref" line
			Case StringUpper(StringMid(StringStripWS($cfg[$x], 8), 1, 8)) = "DEFAULTPREF"
				$cpm = getConfigParamAndValue($cfg[$x], "defaultPref")
				$arCfg[$x - 1][0] = "defaultPref"
				$arCfg[$x - 1][1] = $cpm[0]
				$arCfg[$x - 1][2] = $cpm[1]
				; "user_pref" line
			Case StringUpper(StringMid(StringStripWS($cfg[$x], 8), 1, 9)) = "USER_PREF"
				$cpm = getConfigParamAndValue($cfg[$x], "user_pref")
				$arCfg[$x - 1][0] = "user_pref"
				$arCfg[$x - 1][1] = $cpm[0]
				$arCfg[$x - 1][2] = $cpm[1]
		EndSelect
	Next
	
	Return $arCfg
EndFunc   ;==>parseCfg

; separate text line from firefox auto-configuration file into param<->value array

Func getConfigParamAndValue($line, $paramType)
	Local $tmp, $pos, $len, $var, $val
	Local $cpm[2]

	;ConsoleWrite(StringMid(StringStripWS($cfg[$x], 8), 1, 4) & @crlf)
	;ConsoleWrite(StringStripWS($cfg[$x], 8) & @crlf)

	$pos = StringInStr($line, ",")
	$tmp = StringMid($line, 1, $pos - 1)
	$tmp = StringStripWS($tmp, 8)
	$tmp = StringReplace($tmp, $paramType & '("', "")
	$cpm[0] = StringReplace($tmp, '"', "")
	$tmp = StringStripWS(StringMid($line, $pos), 3)
	$cpm[1] = StringStripWS(StringMid($tmp, 2, StringLen($tmp) - 3), 3)

	Return $cpm
EndFunc   ;==>getConfigParamAndValue

; edit special capabilities.policy... lines

Func editCapabilityPolicies($arCfg)
	Local $arPolicies[1], $rc, $tmp, $line

	_debug("Editing capability policies...")
	
	; try to find capability.policy.policynames list and separate it
	For $i = 0 To UBound($arCfg) - 1
		If $arCfg[$i][1] = "capability.policy.policynames" Then
			$tmp = StringReplace(StringStripWS($arCfg[$i][2], 8), '"', "")
			$arPolicies = StringSplit($tmp, ",")
		EndIf
	Next

	_debug("Currently active policies: " & _ArrayToString($arPolicies, ", ", 1))
	
	; then add/remove policies in capability.policy.policynames and from $arCfg
	For $i = 1 To x($iniName & ".capability_policies.count")
		Local $a = x($iniName & ".capability_policies.policy" & $i)
		$rc = _ArraySearch($arPolicies, $a[1])

		; mark all policy lines regarding actual policy name to be removed, will be rebuild later if applicable
		For $j = 0 To UBound($arCfg) - 1
			If StringInStr($arCfg[$j][1], "capability.policy." & $a[1]) > 0 Then
				_debug("Remove marker for policy rule, will be rebuild later, eventually (" & $a[1] & "): " & $arCfg[$j][0] & '("' & $arCfg[$j][1] & '", ' & $arCfg[$j][2] & ");")
				$arCfg[$j][0] = "remove"
				$arCfg[$j][3] = "to be removed"
			EndIf
		Next

		; remove policy if found and to be removed (sites value = $a[2] = "")
		If ($rc > -1) And ($a[2] = "") Then
			_debug("Removing policy: " & $a[1])
			_ArrayDelete($arPolicies, $rc)
			$arPolicies[0] = $arPolicies[0] - 1
		EndIf
		; add policy if not found and to be added (sites value <> $a[2] = "")
		If ($rc = -1) And ($a[2] <> "") Then
			_debug("Adding policy: " & $a[1])
			_ArrayAdd($arPolicies, $a[1])
			$arPolicies[0] = $arPolicies[0] + 1
		EndIf
		; do nothing, only log
		If ($rc > -1) And ($a[2] <> "") Then
			_debug("Individual policy rule found: " & $a[1])
		EndIf
		
	Next

	; add policy to capability.policy.policynames or add it, if it's missing completely
	$tmp = '"'
	For $j = 1 To $arPolicies[0]
		If $j > 1 Then $tmp &= ","
		$tmp &= $arPolicies[$j]
	Next
	$tmp &= '"'
	$line = _ArraySearch($arCfg, "capability.policy.policynames", 0, 0, 0, 0, 1, 1)
	; now add line if it doesn't exist
	If $line = -1 Then
		ReDim $arCfg[UBound($arCfg) + 1][4]
		local $idx = 0
		If $arCfg[0][0] <> "" Then
			$idx = UBound($arCfg) - 2
		EndIf
		$arCfg[$idx][0] = "pref"
		$arCfg[$idx][1] = "capability.policy.policynames"
		$arCfg[$idx][2] = $tmp
		$arCfg[$idx][3] = "added"
	Else
		$arCfg[$line][2] = $tmp
		$arCfg[$line][3] = "changed"
	EndIf

	; add new/edited policy lines add end of array
	For $i = 1 To x($iniName & ".capability_policies.count")
		Local $a = x($iniName & ".capability_policies.policy" & $i)
		If _ArraySearch($arPolicies, $a[1]) > -1 Then
			; set new values
			Local $max = UBound($arCfg) - 1
			Local $new_lines = (UBound($a) - 1) / 2 ;first val is param type, then always param<->value combinations
			ReDim $arCfg[$max + $new_lines + 1][4]
			
			; set sites value
			_debug("Adding sites parameter for policy: " & $a[0] & '("' & "capability.policy." & $a[1] & ".sites" & '", ' & $a[2] & ");")
			$arCfg[$max][0] = $a[0]
			$arCfg[$max][1] = "capability.policy." & $a[1] & ".sites"
			$arCfg[$max][2] = $a[2]
			$arCfg[$max][3] = "changed/added"
			
			; set additional values
			Local $add = 1
			For $j = 1 To $new_lines - 1
				$add += 1
				_debug("Adding additional parameter for policy: " & $a[0] & '("' & "capability.policy." & $a[1] & "." & $a[$j + $add] & '", ' & $a[$j + $add + 1] & ");")
				$arCfg[$max + $j][0] = $a[0]
				$arCfg[$max + $j][1] = "capability.policy." & $a[1] & "." & $a[$j + $add]
				$arCfg[$max + $j][2] = $a[$j + $add + 1]
				$arCfg[$max + $j][3] = "changed/added"
			Next
		EndIf
	Next

	Return $arCfg
EndFunc   ;==>editCapabilityPolicies

Func editSingleParameter($arCfg)
	
	_debug("Editing single parameters...")

	For $i = 1 To x($iniName & ".single_parameter.count")
		Local $a = x($iniName & ".single_parameter.param" & $i)
		$rc = _ArraySearch($arCfg, $a[1], 0, 0, 0, 0, 1, 1)
		
		; parameter found
		If $rc > -1 Then
			If $a[2] = "" Then ; note: field has to be really empty, and not "" (  pref|value| <> pref|value|""  !!!!)
				_debug("Line removed (" & $rc + 1 & "): " & $arCfg[$rc][0] & '("' & $arCfg[$rc][1] & '", ' & $arCfg[$rc][2] & ");")
				$arCfg[$rc][0] = "remove"
				$arCfg[$rc][3] = "to be removed"
			Else
				_debug("Line changed (" & $rc + 1 & ") old: " & $arCfg[$rc][0] & '("' & $arCfg[$rc][1] & '", ' & $arCfg[$rc][2] & ");")
				_debug("Line changed (" & $rc + 1 & ") new: " & $a[0] & '("' & $arCfg[$rc][1] & '", ' & $a[2] & ");")
				$arCfg[$rc][0] = $a[0]
				$arCfg[$rc][2] = $a[2]
				$arCfg[$rc][3] = "changed"
			EndIf
			
		Else
			; parameter not found, we have to add it
			If $a[2] <> "" Then ; note: field has to be really empty, and not "" (  pref|value| <> pref|value|""  !!!!)
				ReDim $arCfg[UBound($arCfg) + 1][4]
				local $idx = 0
				If $arCfg[0][0] <> "" Then
					$idx = UBound($arCfg) - 2
				EndIf
				_debug("Line added (" & UBound($arCfg) - 1 & ") new: " & $a[0] & '("' & $a[1] & '", ' & $a[2] & ");")
				$arCfg[$idx][0] = $a[0]
				$arCfg[$idx][1] = $a[1]
				$arCfg[$idx][2] = $a[2]
				$arCfg[$idx][3] = "added"
			EndIf
		EndIf
	Next

	Return $arCfg
EndFunc   ;==>editSingleParameter

; output debug messages to console

Func _debug($dbg, $line = @ScriptLineNumber)
	Local $time = "[" & @MDAY & "." & @MON & "." & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] ! DEBUG"
	If $debug Then ConsoleWrite(@CRLF & $time & " (" & $line & "): " & $dbg)
	_writeLog(_formatIOText($dbg))
EndFunc   ;==>_debug

; format message text line for console and log
; if $mark is "?????", then special question format is used

Func _formatIOText($text, $mark = "")
	Local $time = "[" & @MDAY & "." & @MON & "." & @YEAR & " " & @HOUR & ":" & @MIN & ":" & @SEC & "] "

	If $mark = "" Then
		$text = $time & StringReplace($text, @CRLF, @CRLF & $time)
	ElseIf $mark = "?????" Then
		$text = $time & $text & ": "
	Else
		$text = $time & "! " & $mark & ": " & StringReplace($text, @CRLF, @CRLF & $time & "! " & $mark & ": ")
	EndIf

	Return $text
EndFunc   ;==>_formatIOText


; log messages to disc

Func _writeLog($msg, $nocrlf = False)
	; write lines to logfile, even if --quiet is specified
	If $log_mode Then
		Local $file = FileOpen($log_file, 1 + 8) ; create dir and open/create file
		If $nocrlf Then
			FileWrite($file, $msg)
		Else
			FileWrite($file, @CRLF & $msg)
		EndIf
		FileFlush($file)
		FileClose($file)
	EndIf
EndFunc   ;==>_writeLog

; handle command line options

Func _getopts()
	Local $sMsg = '------------------------------------------------------------------------------------------------------------------' & @CRLF ; start line
	$sMsg &= $header & ' v' & $version & ' Command Line' & @CRLF & 'Parsing: ' & _ArrayToString($CmdLine, ' ', 1) & @CRLF & @CRLF ; Message.
	Local $sOpt, $sSubOpt, $sOper
	Local $h_specified = False
	Local $failure = False
	; Options array, entries have the format [short, long, default value]
	Local $aOpts[7][3] = [ _
			['-c', '--config', $GETOPT_REQUIRED_ARGUMENT], _
			['-n', '--no-test', False], _
			['-i', '--inidesc', True], _
			['-s', '--showmod', False], _
			['-d', '--debug', False], _
			['-l', '--log', $log_file], _
			['-h', '--help', True]]

	_GetOpt_Set($aOpts) ; Set options.

	If 0 < $GetOpt_Opts[0] Then ; If there are any options...

		; first loop: analyse parameters and create message texts, exit program if needed
		While 1 ; ...loop through them one by one.
			; Get the next option passing a string with valid options.
			$sOpt = _GetOpt('c:nidlhs') ; p: means -p option requires an argument.
			If Not $sOpt Then ExitLoop ; No options or end of loop.
			; Check @extended above if you want better error handling.
			; The current option is stored in $GetOpt_Opt, it's index (in $GetOpt_Opts)
			; in $GetOpt_Ind and it's value in $GetOpt_Arg.
			Switch $sOpt ; What is the current option?
				Case '?' ; Unknown options come here. @extended is set to $E_GETOPT_UNKNOWN_OPTION
					$sMsg &= 'Unknown option: ' & $GetOpt_Ind & ': ' & $GetOpt_Opt
					$sMsg &= ' with value "' & $GetOpt_Arg & '" (' & VarGetType($GetOpt_Arg) & ').' & @CRLF
					$sMsg &= 'UNKNOWN OPTION passed.' & @CRLF
					$failure = True
				Case ':' ; Options with missing required arguments come here. @extended is set to $E_GETOPT_MISSING_ARGUMENT
					$sMsg &= 'MISSING REQUIRED ARGUMENT for option: ' & $GetOpt_Ind & ': ' & $GetOpt_Opt & @CRLF
					$failure = True
				Case 'n', 'd', 'l', 's'
					$sMsg &= 'Option ' & $GetOpt_Ind & ': ' & $GetOpt_Opt
					$sMsg &= ' with value "' & $GetOpt_Arg & '" (' & VarGetType($GetOpt_Arg) & ')'
					$sMsg &= '.' & @CRLF
					Switch $GetOpt_Opt ; What is the current option?
						Case "d"
							$debug = True
						Case "s"
							$showmod = True
						Case "n"
							$test = False
						Case "l"
							$log_mode = True
							$log_file = $GetOpt_Arg
					EndSwitch
				Case 'c'
					$sMsg &= 'Option ' & $GetOpt_Ind & ': ' & $GetOpt_Opt
					$sMsg &= ' with required value "' & $GetOpt_Arg & '" (' & VarGetType($GetOpt_Arg) & ')'
					$sMsg &= '.' & @CRLF
					$iniName = $GetOpt_Arg
				Case 'h'
					$sMsg &= 'Available command line options:' & @CRLF & @CRLF & _
					'-c' & @TAB & '--config    ' & @TAB & 'Use different configuration file (INI file name with extension)' & @CRLF & _
					'-n' & @TAB & '--no-test   ' & @TAB & 'No test mode, apply changes' & @CRLF & _
					'-i' & @TAB & '--inidesc   ' & @TAB & 'Describe INI file format' & @CRLF & _
					'-d' & @TAB & '--debug     ' & @TAB & 'Show detailed output on console' & @CRLF & _
					'-l' & @TAB & '--log       ' & @TAB & 'Write logfile (optional: specify different logfile name)' & @CRLF & _
					'-h' & @TAB & '--help      ' & @TAB & 'Show this help' & @CRLF & @CRLF & _ 
					'Regarding option -c / --config:' & @CRLF & _
					'You can use different configuration files in the program directory. Just use different names for the files' & @CRLF & _
					'(like config1.ini, my_config.ini, etc.) and specifiy them on the command line as follows:' & @CRLF & @CRLF & _
					'edit_ffcfg --config=my_config' & @CRLF & @CRLF & _
					' or' & @CRLF & @CRLF & _
					'edit_ffcfg -c=my_config' & @CRLF & @CRLF & _
					'Be sure to omit the .ini extension!' & @CRLF & @CRLF & _
					'Default logfile: ' & $log_file & @CRLF & @CRLF
					$h_specified = True
				Case 'i'
					$sMsg &= '0) General INI format description:' & @CRLF & _
					'**********************************' & @CRLF & @CRLF & _
					@TAB & '[general]' & @CRLF & _
					@TAB & 'ff_cfg = <path to firefox auto-configuration file>' & @CRLF & @CRLF & _
					@TAB & '[single_parameter]' & @CRLF & _
					@TAB & 'count = <number of parameters that follow>' & @CRLF & _
					@TAB & 'param1 = <first parameter to be added, deleted or changed>' & @CRLF & _
					@TAB & 'param2 = <second parameter to be added, deleted or changed>' & @CRLF & _
					@TAB & '....' & @CRLF & @CRLF & _
					@TAB & '[capability_policies]' & @CRLF & _
					@TAB & 'count = <number of policies that follow>' & @CRLF & _
					@TAB & 'policy1 = <first policy to be added, deleted or changed>' & @CRLF & _
					@TAB & 'policy2 = <second policy to be added, deleted or changed>' & @CRLF & @CRLF & _
					'I) Single_parameter entry format:' & @CRLF & _
					'*********************************' & @CRLF & @CRLF & _
					'A parameter has to be written in the following format:' & @CRLF & @CRLF & _
					@TAB & '<preference type>|<parameter name>|<parameter value>' & @CRLF & @CRLF & _
					@TAB & '<preference type> is one of values: pref, lockPref, defaultPref, user_pref' & @CRLF & _
					@TAB & '<parameter name> is the exact name, ie. "auto.update.enabled", "social.active", BUT WITHOUT QUOTES' & @CRLF & _
					@TAB & '<parameter value> value of parameter, only use quotes if these are part of the value' & @CRLF & @CRLF & _
					'All values have to be separated by a single | symbol.' & @CRLF & @CRLF & _
					@TAB & 'a) Adding/Editing parameters:' & @CRLF & _
					@TAB & '-----------------------------' & @CRLF & @CRLF & _
					@TAB & 'Example:' & @CRLF & _
					@TAB & @TAB & 'param1=pref|pref.advanced.javascript.disable_button.advanced|false' & @CRLF & _
					@TAB & @TAB & 'param2=lockPref|plugins.hide_infobar_for_outdated_plugin|True' & @CRLF & @CRLF & _
					@TAB & 'Resulting configuration lines:' & @CRLF & _
					@TAB & @TAB & 'pref("pref.advanced.javascript.disable_button.advanced", false);' & @CRLF & _
					@TAB & @TAB & 'lockPref("plugins.hide_infobar_for_outdated_plugin", false);' & @CRLF & @CRLF & _
					@TAB & 'b) Removing a parameter:' & @CRLF & _
					@TAB & '-------------------------' & @CRLF & @CRLF & _
					@TAB & 'If you specify only the first two values and end the second parameter with a | symbol, the parameter will be removed from the file.' & @CRLF & @CRLF & _
					@TAB & @TAB & 'param<n>=<preference type>|<parameter name>|' & @CRLF & @CRLF & _
					@TAB & 'Example:' & @CRLF & _
					@TAB & @TAB & 'param1=pref|auto.update.enable|' & @CRLF & @CRLF & _
					@TAB & 'would remove the line' & @CRLF & @CRLF & _
					@TAB & @TAB & 'pref("auto.update.enable", ...);' & @CRLF & @CRLF & _
					@TAB & 'completely.' & @CRLF & @CRLF & _
					'II) Capability_policies entry format:' & @CRLF & _
					'*************************************' & @CRLF & @CRLF & _
					'A policy has to be written in the following format:' & @CRLF & @CRLF & _
					@TAB & '<preference type>|<policy name>|<sites value>[|<policy.parameter name>|<policy.parameter value>][|<policy.parameter name>|<policy.parameter value>]....' & @CRLF & @CRLF & _
					'Mandatory values:' & @CRLF & @CRLF & _
					@TAB & '<preference type> is one of values: pref, lockPref, defaultPref, user_pref' & @CRLF & _
					@TAB & '<policy name> policy name, ie. "my_policy", BUT WITHOUT QUOTES' & @CRLF & _
					@TAB & '<sites value> site to apply this policy to, ie. "http://my.server.local", "http://my.server.local:4646"' & @CRLF & @CRLF & _
					'Optional values (multiple parameter<->value pairs possible):' & @CRLF & @CRLF & _
					@TAB & '<policy.parameter name> parameter name for this policy' & @CRLF & _
					@TAB & '<policy.parameter value> parameter value for this policy' & @CRLF & @CRLF & _
					'All values have to be separated by a single | symbol.' & @CRLF & @CRLF & _
					@TAB & 'a) Adding/Editing policies:' & @CRLF & _
					@TAB & '---------------------------' & @CRLF & @CRLF & _
					@TAB & 'Example:' & @CRLF & _
					@TAB & @TAB & 'policy1=pref|our_links|"http://server.local.net"|checkloaduri.enabled|"allAccess"' & @CRLF & _
					@TAB & @TAB & 'policy2=pref|more_of_our_links|"http://server2.local.net:4646"|checkloaduri.enabled|"allAccess"|Clipboard.cutcopy|"allAccess"|Clipboard.paste|"allAccess"' & @CRLF & @CRLF & _
					@TAB & 'Resulting configuration lines' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.policynames", "our_links,more_of_our_links");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.our_links.sites", "http://server.local.net");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.our_links.checkloaduri.enabled", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");' & @CRLF & @CRLF & _
					@TAB & 'b) Removing policies:' & @CRLF & _
					@TAB & '---------------------' & @CRLF & @CRLF & _
					@TAB & 'If you specify only the first two values and end the second parameter with a | symbol, the policy will be completely removed from the file.' & @CRLF & @CRLF & _
					@TAB & @TAB & '<preference type>|<policy name>|' & @CRLF & @CRLF & _
					@TAB & 'Let''s take the last example result as an existing configuration. A policy line like' & @CRLF & @CRLF & _
					@TAB & @TAB & 'policy1=pref|our_links|' & @CRLF & @CRLF & _
					@TAB & 'would result in the following change:' & @CRLF & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.policynames", "more_of_our_links");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");' & @CRLF & @CRLF & _
					@TAB & 'c) Regarding already existing policies not mentioned in the INI file:' & @CRLF & _
					@TAB & '---------------------------------------------------------------------' & @CRLF & @CRLF & _
					@TAB & 'Already existing policies, which are not mentioned in the INI file, will be simply retained.' & @CRLF & @CRLF & _
					@TAB & 'Let''s assume you already had the following policy lines in your auto-configuration file:' & @CRLF & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.policynames", "alreadytheir,more_of_our_links");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.alreadytheir", "http://server.local.net");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.alreadytheir", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");' & @CRLF & @CRLF & _
					@TAB & 'If you now apply the following rules' & @CRLF & @CRLF & _
					@TAB & @TAB & 'policy1=pref|our_links|"http://server.local.net"|checkloaduri.enabled|"allAccess"' & @CRLF & _
					@TAB & @TAB & 'policy2=pref|more_of_our_links|' & @CRLF & @CRLF & _
					@TAB & 'the result would be:' & @CRLF & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.policynames", "alreadytheir,our_links");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.policynames", "alreadytheir");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.alreadytheir", "http://server.local.net");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.alreadytheir", "allAccess");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.our_links.sites", "http://server.local.net");' & @CRLF & _
					@TAB & @TAB & 'pref("capability.policy.our_links.checkloaduri.enabled", "allAccess");'  & @CRLF & @CRLF
					$h_specified = True
			EndSwitch
		Wend
		
		If 0 < $GetOpt_Opers[0] Then ; If there are any operands...
			$sMsg &= 'INVALID OPERANDS PASSED. This is not allowed. Check for missing ''='' in --path or --log option!' & @CRLF
			While 1 ; ...loop through them one by one.
				$sOper = _GetOpt_Oper() ; Get the next operand.
				If Not $sOper Then ExitLoop ; no operands or end of loop.
				; Check @extended above if you want better error handling.
				$sMsg &= 'Operand ' & $GetOpt_OperInd & ': ' & $sOper & @CRLF
			WEnd
			$failure = True
		EndIf

		If $failure Then $sMsg &= @CRLF & 'Please check the command line parameters!' & @CRLF

		If $h_specified Or $failure Then ; show help screen or wrong options ?
			ConsoleWrite(@crlf & $sMsg)
			If $failure Then Exit 1
			Exit 0
		EndIf
	EndIf

	; write header to log
	_writeLog(_formatIOText($sMsg))
EndFunc

; Author: MilesAhead
; http://www.autoitscript.com/forum/topic/110768-itaskbarlist3/page__view__findpost__p__910631
; read AssocArray from IniFile Section
; returns number of items read - sets @error on failure

; modified (original see AssoArray.au3): Holger Pandel, 2015: accept full path name of ini

Func _ReadAssocFromIni2($myIni = 'config.ini', $mySection = '', $sSep = "|")
	Local $szDrive, $szDir, $szFName, $szExt, $pathTemp

	$pathTemp = _PathSplit(@ScriptFullPath, $szDrive, $szDir, $szFName, $szExt)

	$sIni = $szFName
	
    If $mySection == '' Then
        $aSection = IniReadSectionNames ($myIni); All sections
        If @error Then 
			_debug("Error while reading section names from: " & $myIni)
			Return SetError(@error, 0, 0)
		EndIf
    Else
        Dim $aSection[2] = [1,$mySection]; specific Section
    EndIf

    For $i = 1 To UBound($aSection)-1

        Local $sectionArray = IniReadSection($myIni, $aSection[$i])
        If @error Then
			_debug("Error while reading section: " & $aSection[$i])
			Return SetError(1, 0, 0)
		EndIf
        For $x = 1 To $sectionArray[0][0]
            If StringInStr($sectionArray[$x][1], $sSep) then
                $posS = _MakePosArray($sectionArray[$x][1], $sSep)
            Else
                $posS = $sectionArray[$x][1]
            EndIf
            x($sIni&"."&$aSection[$i]&"."&$sectionArray[$x][0], $posS)
        Next

    next
    Return $sectionArray[0][0]
EndFunc   ;==>_ReadAssocFromIni