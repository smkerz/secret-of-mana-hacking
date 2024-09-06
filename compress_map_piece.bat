@if (@$)==(@_) goto bat "<!--" @end/*
@echo off
if not exist "%~nx0" cd /D "%~dp0"
if not exist "%~nx0" goto err_pth
if "%~1"=="" goto err_arg
set "_BAT_=%~f0"

:next
shift
if "%~0"=="" goto :eof
if not "%~x0"==".s_p" if not "%~x0"=="" goto err_arg
if not exist "%~n0.s_p" goto err_inp
echo;
cscript.exe //nologo //I "%_BAT_%?.wsf" //Job:Process %~n0
echo;
if not errorlevel 5 echo Piece %~n0 Failure! (%errorlevel%)
if     errorlevel 5 echo Piece %~n0 Success!
goto :next

:: ---

:err_pth
echo;
echo !! An error occurred! [d%errorlevel%]
echo Could not set current directory.
goto err_end

:err_inp
echo;
echo !! An error occurred! [f%errorlevel%]
echo Input file "%~n0.s_p" not found.
goto err_end

:err_arg
echo;
echo !! An error occurred! [b%errorlevel%]
echo Invalid batch script arguments.
echo;
echo Input file "*.s_p" expected.
goto err_end

:err_end
echo;
pause
cls
goto :eof

echo Press any key to exit . . .> con
pause > nul
cls
goto :eof

-->
<package><job/>
<job id="Process"><script language="VBScript">
Option Explicit
Dim iErrorlevel, oShell, oFSO, dInput, sOutput(130), iFilePtr, iLen, iBlock, iBlockPtr, iWidth, iHeight, iOverflow, i, j, k, l, z
Dim dCompInput, sCompOutput(130), iCompOutput(130), bCompRaw, iCompPadding, dTempPrev, dTempNext, iTempPadding, iTempOffset

iErrorlevel = 0

If WScript.Arguments.Count > 0 Then

Set oShell = Nothing
Set oShell = CreateObject("WScript.Shell")
If oShell Is Nothing Then
Else

Set oFSO = Nothing
Set oFSO = CreateObject("Scripting.FileSystemObject")
If oFSO Is Nothing Then
Else

	iErrorlevel = 1

	If oFSO.FileExists(WScript.Arguments(0) & ".s_p") Then

		iErrorlevel = 2

		dInput = BinaryRead(WScript.Arguments(0) & ".s_p")
		If Len(dInput) > &H0000000D& Then
		iBlock	= BYTEStoInt(Mid(dInput,  1, 1))
		iWidth	= BYTEStoInt(Mid(dInput,  2, 4))
		iHeight	= BYTEStoInt(Mid(dInput,  6, 4))
		iLen	= BYTEStoInt(Mid(dInput, 10, 4))
		If iBlock = 1 And iLen = iWidth * iHeight And Len(dInput) = iLen + &H0000000D& Then

			iErrorlevel = 3
'			If oFSO.FileExists("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".uncomp.txt")	Then z = oFSO.DeleteFile("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".uncomp.txt",	True)
'			If oFSO.FileExists("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".txt")		Then z = oFSO.DeleteFile("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".txt",		True)
'			If oFSO.FileExists("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".bin")		Then z = oFSO.DeleteFile("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".bin",		True)

			iBlock = 0
			Do While iBlock < iHeight

				iBlockPtr = &H0000000D&	+ iBlock * iWidth
			iBlock = iBlock + 1
			'	sOutput(iBlock) = ""
				i = 0
				Do While i < iWidth
					j = Asc(Mid(dInput, iBlockPtr + i + 1, 1))
				'	sOutput(iBlock) = sOutput(iBlock) & BYTEtoString(j)
					sOutput(iBlock) = sOutput(iBlock) & Right("0" & Hex(j), 2)
					i = i + 1
				Loop
				sOutput(iBlock) = "RAW	" & sOutput(iBlock) & "	'" & vbCrLf

			WScript.StdOut.Write "."
			Loop
'			WScript.StdOut.Write vbCrLf

			' add brackets
			sOutput(0) = "{ ' map piece data" & vbCrLf _
					& "RAW	" & Right("0" & Hex(LeftShift(iWidth - 1, 1)), 2) & " " & Right("0" & Hex(LeftShift(iHeight - 1, 1)), 2) & vbCrLf _
					& sOutput(0)
			i = UBound(sOutput)
			sOutput(i) = sOutput(i) & "}" & vbCrLf

'			If Len( _
			If BinaryWrite("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".uncomp.txt", _
				Join(sOutput, "") _
			) <> iHeight * 8 + iLen * 2 + 34 + iOverflow * 2 Then
				If iErrorlevel = 3 Then iErrorlevel = 4
			Else
'				iErrorlevel = 5
'			End If ' BinaryWrite (uncomp)

			' compression options:
			' C0-C7	copy	tile  -1,	&07 (1-  8) times
			' C8-CF	copy	tile  -2,	&07 (1-  8) times
			' D0-D7	copy	tile  -3,	&07 (1-  8) times
			' D8-DF	copy	tile  -4,	&07 (1-  8) times
			' E0 7F	repeat	tile  -1 row,	&7F (1-128) times
			' E0 FF	repeat	tile  -2 row,	&7F (1-128) times
			' E1-E7	repeat	tile  -1 row,	&07 (2-  8) times
			' E8 7F	copy	tile  -1,	&7F (1-128) times
			' E8 FF	repeat	tile  -2,	&7F (1-128) times
			' E9 7F	repeat	tile  -3,	&7F (1-128) times
			' E9 FF	repeat	tile  -4,	&7F (1-128) times
			' EA 7F	repeat	tile  -5,	&7F (1-128) times
			' EA FF	repeat	tile  -6,	&7F (1-128) times
			' EB 7F	repeat	tile  -7,	&7F (1-128) times
			' EB FF	repeat	tile  -8,	&7F (1-128) times
			' EC 7F	repeat	tile  -9,	&7F (1-128) times
			' EC FF	repeat	tile -10,	&7F (1-128) times
			' ED 7F	repeat	tile -11,	&7F (1-128) times
			' ED FF	repeat	tile -12,	&7F (1-128) times
			' EE 7F	repeat	tile -13,	&7F (1-128) times
			' EE FF	repeat	tile -14,	&7F (1-128) times
			' EF 7F	repeat	tile -15,	&7F (1-128) times
			' EF FF	repeat	tile -16,	&7F (1-128) times
			' F0 7F	inc	tile  -1,	&7F (1-128) times
			' F0 FF	dec	tile  -1,	&7F (1-128) times
			' F1-F7	inc	tile  -1,	&07 (2-  8) times
			' F8-FF	stamp			&07 (1-  8) stamp
			' FC FF	repeat	tile  -4 row,	&FF (1-256) times
			' FD FF	repeat	tile  -3 row,	&FF (1-256) times
			' FE 7F	repeat	tile  -2 row,+1	&7F (1-128) times
			' FE FF	repeat	tile  -2 row,-1	&7F (1-128) times
			' FF 7F	repeat	tile  -1 row,+1	&7F (1-128) times
			' FF FF	repeat	tile  -1 row,-1	&7F (1-128) times

			dCompInput = ""
			l = Chr(&HFF&)
			i = 0
			Do While i < iWidth * 4
				dCompInput = dCompInput & l
				i = i + 1
			Loop
			dCompInput = dCompInput & Mid(dInput, &H0000000D& + 1)
		'	i = 0
		'	Do While i < 16
				dCompInput = dCompInput & l
		'		i = i + 1
		'	Loop

			iBlock = 0
			i = iWidth
			iCompPadding = 0
			iOverflow = 0
			Do While iBlock < iHeight

				iBlockPtr = iWidth * 4	+ iBlock * iWidth
			iBlock = iBlock + 1
				i = i - iWidth
			'	sCompOutput(iBlock) = ""
				Do While iCompPadding > 0 And i < iWidth 'And Len(sCompOutput(iBlock)) <= iWidth * 2
					sCompOutput(iBlock) = sCompOutput(iBlock) & "  "
					iCompPadding = iCompPadding - 1
					i = i + 1
				Loop
				Do While i < iWidth
					bCompRaw = True
					j = Asc(Mid(dCompInput, iBlockPtr + i + 1, 1))
					k = 0
					l = 0

					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 0, 1))
					dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + 2, 1))
					If dTempPrev = j + 1 Then					' dec
					If dTempNext = j - 1 Then					' dec, 3-128
						iTempPadding = 0
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> j - iTempPadding - 1 Or iTempPadding >= 127
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding >= iCompPadding Then
							iCompPadding = iTempPadding
							k = &HF0&
							l = &H80& Or iCompPadding
							bCompRaw = False
						End If
						End If
					End If
					ElseIf dTempPrev = j - 1 Then					' inc
					If dTempNext = j + 1 Then					' inc, 2-128
						iTempPadding = 0
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> j + iTempPadding + 1 Or iTempPadding >= 127
						If iTempPadding > 0 Then				' min match 2
						If iTempPadding >= iCompPadding Then
							iCompPadding = iTempPadding
						If iTempPadding <= 7 Then				' inc, 2-  8
							k = 0
							l = &HF0& Or iCompPadding
						Else							' inc, 9-128
							k = &HF0&
							l = iCompPadding
						End If
							bCompRaw = False
						End If
						End If
					End If
					ElseIf dTempPrev = j Then					' copy-1
					If dTempNext = j Then						' copy-1, 2-128
						iTempPadding = 0
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> j Or iTempPadding >= 127
						If iTempPadding = iWidth - 1 And i > 0 Then		' complexity reduction
							iTempPadding = iWidth - i - 1
						End If
						If iTempPadding > 0 Then				' min match 2
						If iTempPadding >= iCompPadding Then
							iCompPadding = iTempPadding
						If iTempPadding <= 7 Then				' copy-1, 2-  8
							k = 0
							l = &HC0& Or iCompPadding
						Else							' copy-1, 9-128
							k = &HE8&
							l = iCompPadding
						End If
							bCompRaw = False
						End If
						End If
					End If
					ElseIf dTempNext = j Then					' copy-?
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i - 1, 1))
					If dTempPrev = j Then						' copy-2, 2-  8
						iTempPadding = 0
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> j Or iTempPadding >= 7
						If iTempPadding > 0 Then				' min match 2
						If iTempPadding >= iCompPadding Then
							iCompPadding = iTempPadding
							k = 0
							l = &HC8& Or iCompPadding
							bCompRaw = False
						End If
						End If
					Else
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i - 2, 1))
					If dTempPrev = j Then						' copy-3, 2-  8
						iTempPadding = 0
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> j Or iTempPadding >= 7
						If iTempPadding > 0 Then				' min match 2
						If iTempPadding >= iCompPadding Then
							iCompPadding = iTempPadding
							k = 0
							l = &HD0& Or iCompPadding
							bCompRaw = False
						End If
						End If
					Else
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i - 3, 1))
					If dTempPrev = j Then						' copy-4, 2-  8
						iTempPadding = 0
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> j Or iTempPadding >= 7
						If iTempPadding > 0 Then				' min match 2
						If iTempPadding >= iCompPadding Then
							iCompPadding = iTempPadding
							k = 0
							l = &HD8& Or iCompPadding
							bCompRaw = False
						End If
						End If
					End If
					End If
					End If
					End If

					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth, 1))
					If dTempPrev = j Then						' row-1, 2-128
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding = iWidth - 1 And i > 0 Then		' complexity reduction
							iTempPadding = iWidth - i - 1
						End If
						If iTempPadding > 0 Then				' min match 2
						If iTempPadding >= iCompPadding Then			' high priority
							iCompPadding = iTempPadding
						If iTempPadding <= 7 Then				' row-1, 2-  8
							k = 0
							l = &HE0& Or iCompPadding
						Else							' row-1, 9-128
							k = &HE0&
							l = iCompPadding
						End If
							bCompRaw = False
						End If
						End If
					End If
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth * 2, 1))
					If dTempPrev = j Then						' row-2, 3-128
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth * 2, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding = iWidth - 1 And i > 0 Then		' complexity reduction
							iTempPadding = iWidth - i - 1
						End If
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
							iCompPadding = iTempPadding
							k = &HE0&
							l = &H80& Or iCompPadding
							bCompRaw = False
						End If
						End If
					End If

					For iTempOffset = 2 To 16 Step 1				' repeat 2-16
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iTempOffset, 1))
					If dTempPrev = j Then						' repeat ?, 3-128
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iTempOffset, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
						If Not k = &HE8& Then					' special rule
							iCompPadding = iTempPadding
							k = &HE0& Or (8 + RightShift(iTempOffset - 1, 1))
							If (iTempOffset And 1) = 1 Then
							l = iCompPadding
							Else
							l = &H80& Or iCompPadding
							End If
							bCompRaw = False
						End If
						End If
						End If
					End If
					Next

				If False Then								' new opcodes
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth * 3, 1))
					If dTempPrev = j Then						' row-3, 3-256
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth * 3, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 255
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
							iCompPadding = iTempPadding
							k = &HFD&
							l = iCompPadding
							bCompRaw = False
						End If
						End If
					End If
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth * 4, 1))
					If dTempPrev = j Then						' row-4, 3-256
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth * 4, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 255
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
							iCompPadding = iTempPadding
							k = &HFC&
							l = iCompPadding
							bCompRaw = False
						End If
						End If
					End If
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth + 1, 1))
					If dTempPrev = j Then						' row-1+1, 3-128
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth + 1, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
							iCompPadding = iTempPadding
							k = &HFF&
							l = iCompPadding
							bCompRaw = False
						End If
						End If
					End If
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth - 1, 1))
					If dTempPrev = j Then						' row-1-1, 3-128
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth - 1, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
							iCompPadding = iTempPadding
							k = &HFF&
							l = &H80& Or iCompPadding
							bCompRaw = False
						End If
						End If
					End If
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth * 2 + 1, 1))
					If dTempPrev = j Then						' row-2+1, 3-128
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth * 2 + 1, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
							iCompPadding = iTempPadding
							k = &HFE&
							l = iCompPadding
							bCompRaw = False
						End If
						End If
					End If
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 1 - iWidth * 2 - 1, 1))
					If dTempPrev = j Then						' row-2-1, 3-128
						iTempPadding = -1
						Do
							iTempPadding = iTempPadding + 1
							dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2 - iWidth * 2 - 1, 1))
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding > 1 Then				' min match 3
						If iTempPadding > iCompPadding Then			' low priority
							iCompPadding = iTempPadding
							k = &HFE&
							l = &H80& Or iCompPadding
							bCompRaw = False
						End If
						End If
					End If
				End If									' new opcodes

					If Not bCompRaw Then						' defer copy
					If (k And &HF0&) = &HE0& Then
					If k = &HE0& Then	'Or (l And &HF8&) = &HE0& Then
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 2, 1))
					If dTempPrev = j Then
					dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + 3, 1))
					If dTempNext = dTempPrev Then
						iTempPadding = 1
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 2, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 127
						If iTempPadding > iCompPadding Then			' defer
							bCompRaw = True
						End If
					End If
					End If
					ElseIf Not (k = &HE8& And (l And &H80&) = 0) Then
					dTempPrev = Asc(Mid(dCompInput, iBlockPtr + i + 2, 1))
					dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + 3, 1))
					If dTempNext = dTempPrev Then
						iTempPadding = 0
						Do
							iTempPadding = iTempPadding + 1
							dTempNext = Asc(Mid(dCompInput, iBlockPtr + i + iTempPadding + 3, 1))
						Loop Until dTempNext <> dTempPrev Or iTempPadding >= 7
						If iTempPadding > iCompPadding Then			' defer
							bCompRaw = True
						End If
					End If
					End If ' E0??/!E80?
					End If ' E?
					End If

					If bCompRaw Then
						sCompOutput(iBlock) = sCompOutput(iBlock) & Right("0" & Hex(j), 2)
						iCompOutput(iBlock) = iCompOutput(iBlock) & Chr(j)
						iCompPadding = 0
					Else
						If Not k = 0 Then
							sCompOutput(iBlock) = sCompOutput(iBlock) & Right("0" & Hex(k), 2)
							iCompOutput(iBlock) = iCompOutput(iBlock) & Chr(k)
							If iCompPadding > 0 And i < iWidth - 2 Then
								iCompPadding = iCompPadding - 1
								i = i + 1
							Else
								iOverflow = iOverflow + 1
							End If
						'	k = 0
						End If
						sCompOutput(iBlock) = sCompOutput(iBlock) & Right("0" & Hex(l), 2)
						iCompOutput(iBlock) = iCompOutput(iBlock) & Chr(l)
						Do While iCompPadding > 0 And i < iWidth - 1 'And Len(sCompOutput(iBlock)) < iWidth * 2
							sCompOutput(iBlock) = sCompOutput(iBlock) & "  "
							iCompPadding = iCompPadding - 1
							i = i + 1
						Loop
					End If
					i = i + 1
				Loop ' While i < iWidth
				If Trim(sCompOutput(iBlock)) = "" Then
					sCompOutput(iBlock) = "' RAW	" & sCompOutput(iBlock) & "	'" & vbCrLf
					iOverflow = iOverflow + 1
				Else
					sCompOutput(iBlock) = "RAW	" & sCompOutput(iBlock) & "	'" & vbCrLf
				End If

			WScript.StdOut.Write "."
			Loop ' iBlock < iHeight
'			WScript.StdOut.Write vbCrLf

			' add brackets
			sCompOutput(0) = "{ ' map piece data" & vbCrLf _
					& "RAW	" & Right("0" & Hex(LeftShift(iWidth - 1, 1)), 2) & " " & Right("0" & Hex(LeftShift(iHeight - 1, 1)), 2) & vbCrLf _
					& sCompOutput(0)
			iCompOutput(0) = Chr(LeftShift(iWidth - 1, 1)) & Chr(LeftShift(iHeight - 1, 1)) _
					& iCompOutput(0)
			i = UBound(sCompOutput)
			sCompOutput(i) = sCompOutput(i) & "}" & vbCrLf

			If BinaryWrite("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".txt", _
				Join(sCompOutput, "") _
			) <> iHeight * 8 + iLen * 2 + 34 + iOverflow * 2 Then
				If iErrorlevel = 3 Then iErrorlevel = 4
			Else
				iErrorlevel = 5
				If BinaryWrite("Secret_of_Mana.map_piece." & WScript.Arguments(0) & ".bin", _
					Join(iCompOutput, "") _
				) < 2 Then
					iErrorlevel = 4
				End If
			End If ' BinaryWrite

			End If ' BinaryWrite (uncomp)
		End If ' iLen
		End If ' Len
	End If ' FileExists()

Set oFSO = Nothing
End If ' oFSO Is Nothing

Set oShell = Nothing
End If ' oShell Is Nothing

End If ' WScript.Arguments.Count

WScript.Quit(iErrorlevel)
' 0 = failure, critical error
' 1 = failure, missing input file
' 2 = failure, bad input file
' 3 = failure, critical error
' 4 = failure, bad output size
' 5 = success

' ---

' http://chris.wastedhalo.com/2014/05/more-binarybitwise-functions-for-vbscript/
'*******************************************************************************
'*	LeftShift(AnyNumber, BitsToShiftBy)
'*	 Returns a new number with bits shifted. 0's are shifted in from the
'*	 right, bits will fall off on the left.
'*******************************************************************************
Function LeftShift(pValue, pShift)
	Dim NewValue, PrevValue, i
	PrevValue = pValue
	For i = 1 to pShift
		Select Case VarType(pValue)
			Case vbLong
				NewValue = (PrevValue And "&H3FFFFFFF") * 2
				If PrevValue And "&H40000000" Then NewValue = NewValue Or "&H80000000"
				NewValue = CLng(NewValue)
			Case vbInteger
				NewValue = (PrevValue And "&H3FFF") * 2
				If PrevValue And "&H4000" Then NewValue = NewValue Or "&H8000"
				NewValue = CInt("&H"+ Hex(NewValue))
			Case vbByte
				NewValue = CByte((PrevValue And "&H7F") * 2)
			Case Else: Err.Raise 13 ' Not a supported type 
		End Select
		PrevValue = NewValue
	Next
	LeftShift = NewVAlue
End Function
Function LeftShift16(ByRef pValue, ByRef pShift)
	Dim NewValue, PrevValue, i
	PrevValue = pValue
	For i = 1 to pShift
				NewValue = (PrevValue And "&H3FFF") * 2
				If PrevValue And "&H4000" Then NewValue = NewValue Or "&H8000"
				NewValue = CInt("&H"+ Hex(NewValue))
		PrevValue = NewValue
	Next
	LeftShift16 = NewValue
End Function

' http://chris.wastedhalo.com/2014/05/more-binarybitwise-functions-for-vbscript/
'*******************************************************************************
'*	RightShift(AnyNumber, BitsToShiftBy)
'*	 Returns a new number with bits shifted
'*	 0's are shifted in from the left. Bits will fall off on the right.
'*******************************************************************************
Function RightShift(pValue, pShift)
	Dim NewValue, PrevValue, i
	PrevValue = pValue
	For i = 1 to pShift
		Select Case VarType(pValue)
			Case vbLong
				NewValue = Int((PrevValue And "&H7FFFFFFF") / 2)
				If PrevValue And "&H80000000" Then NewValue = NewValue Or "&H40000000"
				NewValue = CLng(NewValue)
			Case vbInteger
				NewValue = Int((PrevValue And "&H7FFF") / 2)
				If PrevValue And "&H8000" Then NewValue = NewValue Or "&H4000"
				NewValue = CInt(NewValue)
			Case vbByte
				NewValue = CByte(PrevValue / 2)
			Case Else: Err.Raise 13 ' Not a supported type
		End Select
		PrevValue = NewValue
	Next
	RightShift = PrevValue
End Function
Function RightShift16(ByRef pValue, ByRef pShift)
	Dim NewValue, PrevValue, i
	PrevValue = pValue
	For i = 1 to pShift
				NewValue = Int((PrevValue And "&H7FFF") / 2)
				If PrevValue And "&H8000" Then NewValue = NewValue Or "&H4000"
				NewValue = CInt(NewValue)
		PrevValue = NewValue
	Next
	RightShift16 = PrevValue
End Function

' ---

Function BYTEStoInt(sInput)
	Dim i, j, k, l
	l = Len(sInput)
	j = 0
	If l > 0 Then
		k = &H00000001&
		For i = 1 To l
			j = j + Asc(Mid(sInput, i, 1)) * k
			k = k * &H00000100&
		Next
	End If
	BYTEStoInt = j
End Function
Function CountedString(sInput)
	CountedString = sInput
	iFilePtr = iFilePtr + Len(sInput)
End Function
Function DWORDtoString(iInput)
	If iInput > &H7FFFFFFF& Then iInput = iInput - 4294967296
	DWORDtoString =   Chr(CByte((iInput And &H000000FF&) / &H00000001&)) _
			& Chr(CByte((iInput And &H0000FF00&) / &H00000100&)) _
			& Chr(CByte((iInput And &H00FF0000&) / &H00010000&)) _
			& Chr(CByte((iInput And &H7F000000&) / &H01000000& - (iInput < 0) * &H80))
	iFilePtr = iFilePtr + 4
End Function
Function  WORDtoString(iInput)
	If iInput > &H7FFFFFFF& Then iInput = iInput - 4294967296
	 WORDtoString =   Chr(CByte((iInput And &H000000FF&) / &H00000001&)) _
			& Chr(CByte((iInput And &H0000FF00&) / &H00000100&))
	iFilePtr = iFilePtr + 2
End Function
Function  BYTEtoString(iInput)
	If iInput > &H7FFFFFFF& Then iInput = iInput - 4294967296
	 BYTEtoString =   Chr(CByte((iInput And &H000000FF&) / &H00000001&))
	iFilePtr = iFilePtr + 1
End Function
' https://stackoverflow.com/questions/6060529/read-and-write-binary-file-in-vbscript
Function BinaryRead(strPath)
'	Dim oFSO : Set oFSO = CreateObject("Scripting.FileSystemObject")
	Dim oFile : Set oFile = oFSO.GetFile(strPath)
	If IsNull(oFile) Then
'		MsgBox("File not found: " & vbCrLf & strPath)
		BinaryRead = ""
		Exit Function
	End If

	With oFile.OpenAsTextStream()
		BinaryRead = .Read(oFile.Size)
		.Close
	End With
End Function
Function BinaryWrite(strPath, strBinary)
'	Dim oFSO : Set oFSO = CreateObject("Scripting.FileSystemObject")
	Err.Clear
	On Error Resume Next
	Dim oTxtStream : Set oTxtStream = oFSO.CreateTextFile(strPath)
	If Err.Number <> 0 Then
	On Error GoTo 0
'		MsgBox(Err.Description)
		BinaryWrite = 0
		Exit Function
	End If
	On Error GoTo 0

	With oTxtStream
		.Write(strBinary)
		.Close
	End With
	Set oTxtStream = Nothing

	Dim oFile : Set oFile = oFSO.GetFile(strPath)
	If IsNull(oFile) Then
'		MsgBox("File not found: " & vbCrLf & strPath)
		BinaryWrite = 0
		Exit Function
	End If
	BinaryWrite = oFile.Size
End Function
</script></job>
</package>
<!--
:eof *///-->
