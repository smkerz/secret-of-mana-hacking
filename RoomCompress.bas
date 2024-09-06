Attribute VB_Name = "RoomCompress"
Public out As New RoomInfoClass
Public dataOut() As Variant

Type CompressCalculsCase
    value As Variant
    bytesSavedGeneralArr() As Variant
    gapGeneralArr() As Variant
    funcArr() As Variant
    funcArgArr() As Variant
    jumpArr() As Variant
End Type

Type CompressCalculsCaseWithoutProba
    value As Variant
    bytesSavedGeneral As Variant
    gapGeneral As Variant
    func As Variant
    funcArg As Variant
    jump As Variant
End Type

Public x_pos As Integer
Public y_pos As Integer

Public Width_map As Integer
Public Height_map As Integer

Public windowNextBufferLen As Integer

Private Function GetWindowsPatternFunctionPlusValue() As Variant
    Dim patternArr(1 To 1) As Variant
    
    patternArr(1) = Array(1)

    GetWindowsPatternFunctionPlusValue = patternArr
End Function

Private Function GetWindowsPatternFunctionPreviousOneByte() As Variant
    Dim patternArr(1 To 4) As Variant
    
    patternArr(1) = Array(1)
    patternArr(2) = Array(2)
    patternArr(3) = Array(3)
    patternArr(4) = Array(4)

    GetWindowsPatternFunctionPreviousOneByte = patternArr
End Function

Private Function GetWindowsPatternFunctionPrevious() As Variant
    Dim patternArr(1 To 16) As Variant
    
    patternArr(1) = Array(1, 1)
    patternArr(2) = Array(1, 2)
    patternArr(3) = Array(1, 3)
    patternArr(4) = Array(1, 4)
    patternArr(5) = Array(1, 5)
    patternArr(6) = Array(1, 6)
    patternArr(7) = Array(1, 7)
    patternArr(8) = Array(1, 8)
    patternArr(9) = Array(1, 9)
    patternArr(10) = Array(1, 10)
    patternArr(11) = Array(1, 11)
    patternArr(12) = Array(1, 12)
    patternArr(13) = Array(1, 13)
    patternArr(14) = Array(1, 14)
    patternArr(15) = Array(1, 15)
    patternArr(16) = Array(1, 16)
    GetWindowsPatternFunctionPrevious = patternArr
End Function

Private Function GetWindowsPatternFunctionAbove(Width As Integer) As Variant
    Dim patternArr(1 To 2) As Variant
    patternArr(1) = Array(-(Width), windowNextBufferLen)    ' Fonction E0
    patternArr(2) = Array(-(2 * Width), windowNextBufferLen)    ' Fonction E0
    
    GetWindowsPatternFunctionAbove = patternArr
End Function

Public Sub CompressRoom()

    Set wb = ThisWorkbook
    
    ' Feuille courante
    Dim inputSheetName As String
    Dim inputSheet As Worksheet
    inputSheetName = GetActiveSheetName()
    Set inputSheet = wb.Sheets(inputSheetName)

    ' Lecture de la feuille courante
    Dim roomData As New RoomInfoClass
    roomData.ReadRoom inputSheet
    
    ' Calcul de la pièce compressé
    Dim compressedRoom As New RoomInfoClass
    Set compressedRoom = CompressRoomW(roomData)
    
    ' Feuille sortante
    Dim outputSheetName As String
    Dim outputSheet As Worksheet
    outputSheetName = inputSheetName & "_c"
    Set outputSheet = CreateSheetIfNotExist(outputSheetName)
    
    compressedRoom.WriteRoom outputSheet

End Sub

Public Function CompressRoomW(roomData As RoomInfoClass) As RoomInfoClass
    
    Width_map = roomData.Width_map
    Height_map = roomData.Height_map
    out.Width_map = Width_map
    out.Height_map = Height_map
    
    aire_map = Width_map * Height_map

    ' Calcul de la fenêtre de compression, Next Window
    windowNextBufferLen = ConvertHexToDec("7F") + 1
    
    ReDim dataOut(Height_map - 1, Width_map - 1)
    
    ' Calcul du masque de pattern
    maskArrWindowsPatternPreviousOneByte = GetWindowsPatternFunctionPreviousOneByte()
    maskArrWindowsPatternPrevious = GetWindowsPatternFunctionPrevious()
    maskArrWindowsPatternAbove = GetWindowsPatternFunctionAbove(Width_map)
    maskArrWindowsPatternPlusValue = GetWindowsPatternFunctionPlusValue()

    Dim i As Long
    Dim j As Long

    ' Initialisation du tableau des probabilités
    Dim CompressCalculsCaseArr() As CompressCalculsCaseWithoutProba
    ReDim CompressCalculsCaseArr(1 To aire_map)

    'Read data values and convert 2D array to 1D array
    Dim hexValue As String
    Dim hexArray() As Variant
    ReDim hexArray(1 To aire_map)

    hexArray = FlattenArray(roomData.DataRoom)
    
    ' Tableau des bytes sauvés pour choisir la meilleure méthode
    Dim funcArr() As Variant
    Dim funcArgArr() As Variant
    Dim bytesSavedArr() As Variant
    Dim bytesSavedGeneralArr() As Variant
    Dim gapGeneralArr() As Variant
    Dim jumpArr() As Variant

    ' Pour toutes les données du tableau
    i = 1
    
    Dim BytesSaved As Long
    Dim gap As Long
    Dim func As String
    Dim funcArg As String
    Dim jump As Long
    Dim caseNumber As Integer
    Dim windowBuffer() As Variant
    
    Dim CompressCalculsTest As CompressCalculsCaseWithoutProba
    
    Do Until i >= aire_map
    
        ' Debug
        If i = 81 Then 'And caseNumber = 16 Then
            a = 1
        End If
     
        CompressCalculsTest = CompressCalculsCaseArr(i)

        CompressCalculsCaseArr(i).bytesSavedGeneral = 0
        hexValue = hexArray(i)
        CompressCalculsCaseArr(i).value = FormatHexToBytes(hexValue)

        ' Take values over a (80)h window, the next values matching window
        Dim windowNextBuffer() As Variant ' Declare windowBuffer as an array
        If (i + windowNextBufferLen - 1) <= UBound(hexArray) Then
            windowNextBuffer = SubArray(hexArray, i, i + windowNextBufferLen - 1)
        Else
            windowNextBuffer = SubArray(hexArray, i, UBound(hexArray))
        End If
        
        ' Previous Windows with pattern definition
        ' Fonction E8 à EF
        For caseNumber = 1 To UBound(maskArrWindowsPatternPrevious)

            windowBuffer = SubArray(hexArray, _
                                            i - CInt(maskArrWindowsPatternPrevious(caseNumber)(1)), _
                                            i - CInt(maskArrWindowsPatternPrevious(caseNumber)(0)))
                                            
            ' Si windowReverseBuffer n'est pas hors limite
            If IsArrayEmpty(windowBuffer) Then Exit For
            
            '' En test suite au bug du 27/11/2023
            
            ' Le buffer de compression dans la ROM ne dépasse jamais 2 x largeur de la pièce
            ' Ainsi, impossible d'utiliser EF 84 (16 tiles en arrière) sur une pièce de largeur 6 par exemple
            'If maskArrWindowsPatternPrevious(caseNumber)(1) > 2 * Width_map Then Exit For
                
            'godlike
            makor = i Mod Width_map
            makor = makor + Width_map
            If maskArrWindowsPatternPrevious(caseNumber)(1) > makor Then Exit For
              
            ' Pour tout les masques, nous devons comparer les valeurs entre windowNextBuffer et windowReverseBuffer
            CheckPatternWithFunctionPrevious windowNextBuffer, windowBuffer, BytesSaved, gap, func, funcArg, jump
                                                                                                                
            ' à supprimer, réglé deux lignes plus haut
            ' Vérification assez mauvaise, il faut enlever une de deux conditions
            ' J'ai rajouté cette condtions pour palier aux problème :
            ' tout ça bug si les cellules de référence ne sont pas sur la même ligne de map que le E…
            'g = i Mod Width_map
            'If g > 2 Or func = "E8" Then
            If BytesSaved > CompressCalculsCaseArr(i).bytesSavedGeneral Then
            '    If BytesSaved < 2 * Width_map Or func = "E8" Then
                    CompleteCase CompressCalculsCaseArr(i), BytesSaved, gap, func, funcArg, jump
            '    End If
            End If
                                                                                  
        Next caseNumber

        ' Above Windows with pattern definition
        ' Fonction E et E0
        For caseNumber = 1 To UBound(maskArrWindowsPatternAbove)
        
            windowBuffer = SubArray(hexArray, _
                                            i + CInt(maskArrWindowsPatternAbove(caseNumber)(0)), _
                                            i + CInt(maskArrWindowsPatternAbove(caseNumber)(1)))
                                            
            ' Si windowReverseBuffer n'est pas hors limite
            If IsArrayEmpty(windowBuffer) Then Exit For

            CheckPatternWithFunctionAbove windowNextBuffer, windowBuffer, BytesSaved, CInt(caseNumber), func, funcArg, jump

            If BytesSaved > CompressCalculsCaseArr(i).bytesSavedGeneral Then
                CompleteCase CompressCalculsCaseArr(i), BytesSaved, gap, func, funcArg, jump
            End If
                                                                              
        Next caseNumber

        ' Previous Windows with one byte pattern definition
        ' Fonction C et D
        For caseNumber = 1 To UBound(maskArrWindowsPatternPreviousOneByte)
        
            windowBuffer = SubArray(hexArray, _
                                            i - CInt(GetWindowsPatternFunctionPreviousOneByte(caseNumber)(0)), _
                                            i - CInt(GetWindowsPatternFunctionPreviousOneByte(caseNumber)(0)))
                                            
            ' Si windowReverseBuffer n'est pas hors limite
            If IsArrayEmpty(windowBuffer) Then Exit For
                                            
            ' Pour tout les masques, nous devons comparer les valeurs entre windowNextBuffer et windowReverseBuffer
            gap = CInt(GetWindowsPatternFunctionPreviousOneByte(caseNumber)(0))
            CheckPatternWithFunctionPreviousOneByte windowNextBuffer, windowBuffer, BytesSaved, gap, func, funcArg, jump
                                                                          
            If BytesSaved > CompressCalculsCaseArr(i).bytesSavedGeneral Then
                CompleteCase CompressCalculsCaseArr(i), BytesSaved, gap, func, funcArg, jump
            End If
                                                                              
        Next caseNumber

        ' Previous Windows with plus value patter
        For caseNumber = 1 To UBound(maskArrWindowsPatternPlusValue)
        
            windowBuffer = SubArray(hexArray, _
                                            i - CInt(GetWindowsPatternFunctionPreviousOneByte(caseNumber)(0)), _
                                            i - CInt(GetWindowsPatternFunctionPreviousOneByte(caseNumber)(0)))
                                            
            ' Si windowReverseBuffer n'est pas hors limite
            If IsArrayEmpty(windowBuffer) Then Exit For
                                            
            ' Pour tout les masques, nous devons comparer les valeurs entre windowNextBuffer et windowReverseBuffer
            CheckPatternWithFunctionPlusValue windowNextBuffer, windowBuffer, BytesSaved, gap, func, funcArg, jump
                                                                          
            If BytesSaved > CompressCalculsCaseArr(i).bytesSavedGeneral Then
                CompleteCase CompressCalculsCaseArr(i), BytesSaved, gap, func, funcArg, jump
            End If
                                                                              
        Next caseNumber

    ' i = i + 1 will explore all cases, would be useful if we adapt the algorithm
    ' For the instance we calculate only the cases which are compressed for time performance
    If CompressCalculsCaseArr(i).jump = 0 Then
        i = i + 1
    Else
        i = i + CompressCalculsCaseArr(i).jump
    End If
    
    Loop


    '' Dans le cas du calcul de tout
    ' On déduit le meilleur chemin (à priori car l'algorithme n'est pas adaptatif (beaucoup trop compliqué))
    ' Pour cela, on parcourt toutes les cases contenant les probabilité et on choisit la méthode qui sauve le plus de bytes
    'For i = 1 To aire_map
    '    If Not IsArrayEmpty(CompressCalculsCaseArr(i).bytesSavedGeneralArr) Then
    '        bestMethodIndex = GetIndexOfMaxValue(CompressCalculsCaseArr(i).bytesSavedGeneralArr)
    '        CompressCalculsCaseArr(i).bytesSavedGeneralArr(1) = CompressCalculsCaseArr(i).bytesSavedGeneralArr(bestMethodIndex)
    '        CompressCalculsCaseArr(i).gapGeneralArr(1) = CompressCalculsCaseArr(i).gapGeneralArr(bestMethodIndex)
    '        CompressCalculsCaseArr(i).funcArr(1) = CompressCalculsCaseArr(i).funcArr(bestMethodIndex)
    '        CompressCalculsCaseArr(i).funcArgArr(1) = CompressCalculsCaseArr(i).funcArgArr(bestMethodIndex)
    '        CompressCalculsCaseArr(i).jumpArr(1) = CompressCalculsCaseArr(i).jumpArr(bestMethodIndex)
    '    End If
    'Next i


    x_pos = 1
    y_pos = 1
    i = 1
    Do Until i >= aire_map

        ' ????
        ' Vérification assez mauvaise, il faut enlever une de deux conditions
        ' J'ai rajouté cette condtions pour palier aux problème :
        ' tout ça bug si les cellules de référence ne sont pas sur la même ligne de map que le E…
        'If CompressCalculsCaseArr(i).bytesSavedGeneral = 0 Or CompressCalculsCaseArr(i).jump = 0 Then
        If CompressCalculsCaseArr(i).jump = 0 Then
            dataOut(y_pos - 1, x_pos - 1) = CStr(CompressCalculsCaseArr(i).value)
            IncrementCursors x_pos, y_pos, 1
            i = i + 1

        Else
            dataOut(y_pos - 1, x_pos - 1) = CStr(CompressCalculsCaseArr(i).func)
            IncrementCursors x_pos, y_pos, 1
            
            If Not Len(CompressCalculsCaseArr(i).funcArg) = 0 Then
                dataOut(y_pos - 1, x_pos - 1) = CStr(CompressCalculsCaseArr(i).funcArg)
            End If
            IncrementCursors x_pos, y_pos, -1
            
            ' Le sens des incrémentations est très important !
            IncrementCursors x_pos, y_pos, CompressCalculsCaseArr(i).jump
            i = i + CompressCalculsCaseArr(i).jump

        End If
    Loop
    
    out.DataRoom = dataOut
    Set CompressRoomW = out
    
End Function

' Fonction F
Sub CheckPatternWithFunctionPlusValue(windowBuffer() As Variant, _
                                        windowSliding() As Variant, _
                                        ByRef BytesSaved As Long, _
                                        ByRef gap As Long, _
                                        ByRef func As String, _
                                        ByRef funcArg As String, _
                                        ByRef jump As Long)
                                        
    Dim windowBufferTmp() As Variant
    windowBufferTmp = windowBuffer
    
    ' Initialize counter
    Dim counterByteSaved As Long
    counterByteSaved = 0
    func = Empty
    funcArg = Empty
    jump = 0

    ' Slide window across the array
    Dim windowBufferLength As Long
    Dim SlidingWindowsLength As Long
    windowBufferLength = UBound(windowBufferTmp)
    SlidingWindowsLength = UBound(windowSliding)
    
    Dim i As Long
    Dim previousValue As Variant
    previousValue = windowSliding(1)
    For i = 1 To windowBufferLength
        valuePlusOne = ConvertDecToHex(ConvertHexToDec(CStr(previousValue)) + 1)
        If windowBufferTmp(1) = valuePlusOne Then
            counterByteSaved = counterByteSaved + SlidingWindowsLength
            previousValue = valuePlusOne
            windowBufferTmp = RemoveFirstElement(windowBufferTmp)
        Else
            Exit For
        End If
    Next i
    
    ' Calcul de la fonction à utiliser
    If counterByteSaved > 1 And counterByteSaved <= 7 Then
        BytesSaved = counterByteSaved - 1
        func = FormatHexToBytes("F" & ConvertDecToHex(counterByteSaved - 1))
        funcArg = Empty
        jump = counterByteSaved
        
    End If
End Sub

' Fonction C et D
Sub CheckPatternWithFunctionPreviousOneByte(windowBuffer() As Variant, _
                                        windowSliding() As Variant, _
                                        ByRef BytesSaved As Long, _
                                        ByRef gap As Long, _
                                        ByRef func As String, _
                                        ByRef funcArg As String, _
                                        ByRef jump As Long)
                                        
    Dim windowBufferTmp() As Variant
    windowBufferTmp = windowBuffer
    
    ' Initialize counter
    Dim counterByteSaved As Long
    counterByteSaved = 0
    func = Empty
    funcArg = Empty
    jump = 0

    ' Slide window across the array
    Dim windowBufferLength As Long
    Dim SlidingWindowsLength As Long
    windowBufferLength = UBound(windowBufferTmp)
    SlidingWindowsLength = UBound(windowSliding)
    
    Dim i As Long
    Dim match As Boolean
    Dim exitLoop As Boolean
    beginFlag = False
    match = True
    For i = 1 To windowBufferLength
        If windowBufferTmp(1) = windowSliding(1) Then
            counterByteSaved = counterByteSaved + SlidingWindowsLength
            windowBufferTmp = RemoveFirstElement(windowBufferTmp)
        End If
    Next i
    
    ' Calcul de la fonction à utiliser
    If gap = 1 And counterByteSaved > 1 And counterByteSaved <= 8 Then
        BytesSaved = counterByteSaved + 1
        func = FormatHexToBytes("C" & ConvertDecToHex(counterByteSaved - 1))
        funcArg = Empty
        jump = counterByteSaved
        
    ElseIf gap = 2 And counterByteSaved > 1 And counterByteSaved <= 8 Then
        BytesSaved = counterByteSaved + 1
        func = FormatHexToBytes("C" & ConvertDecToHex(ConvertHexToDec(8) + counterByteSaved - 1))
        funcArg = Empty
        jump = counterByteSaved
    
    ElseIf gap = 3 And counterByteSaved > 1 And counterByteSaved <= 8 Then
        BytesSaved = counterByteSaved + 1
        func = FormatHexToBytes("D" & ConvertDecToHex(counterByteSaved - 1))
        funcArg = Empty
        jump = counterByteSaved
        
    ElseIf gap = 4 And counterByteSaved > 1 And counterByteSaved <= 8 Then
        BytesSaved = counterByteSaved + 1
        func = FormatHexToBytes("D" & ConvertDecToHex(ConvertHexToDec(8) + counterByteSaved - 1))
        funcArg = Empty
        jump = counterByteSaved
    End If
End Sub

'Fonction E et E0
Sub CheckPatternWithFunctionAbove(windowBuffer() As Variant, _
                                        windowSliding() As Variant, _
                                        ByRef BytesSaved As Long, _
                                        ByRef gap As Long, _
                                        ByRef func As String, _
                                        ByRef funcArg As String, _
                                        ByRef jump As Long)
    Dim windowBufferTmp() As Variant
    windowBufferTmp = windowBuffer
    windowBufferLength = UBound(windowBufferTmp)
    
    ' Initialize counter
    'Dim counterByteSaved As Long
    windowBufferCounter = 1
    funcArg = Empty
    jump = 0
    
    Dim cpt As Long
    cpt = 0
                       
    Do While windowSliding(windowBufferCounter) = windowBufferTmp(windowBufferCounter)
        
        cpt = cpt + 1
        windowBufferCounter = windowBufferCounter + 1
        If windowBufferCounter >= windowBufferLength Then cpt = cpt + 1: Exit Do
        
    Loop
              
    
    ' Calcul de la fonction à utiliser
    If cpt > 1 Then
        If gap = 1 Then
            If windowBufferCounter > 1 And windowBufferCounter <= 9 Then
                BytesSaved = windowBufferCounter + 2
                func = FormatHexToBytes("E" & ConvertDecToHex(cpt - 1))
                funcArg = Empty
                jump = windowBufferCounter - 1
                
            Else
                BytesSaved = windowBufferCounter + 1
                func = "E0"
                funcArg = FormatHexToBytes(ConvertDecToHex(cpt - 1))
                jump = cpt
                
            End If
        ElseIf gap = 2 Then
            BytesSaved = windowBufferCounter + 1
            func = "E0"
            funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + cpt - 1))
            jump = cpt
            
        End If
    End If
    
                  
End Sub

'Fonction E8 à EF
Sub CheckPatternWithFunctionPrevious(windowBuffer() As Variant, _
                                        windowSliding() As Variant, _
                                        ByRef BytesSaved As Long, _
                                        ByRef gap As Long, _
                                        ByRef func As String, _
                                        ByRef funcArg As String, _
                                        ByRef jump As Long)
                                        
    Dim windowBufferTmp() As Variant
    windowBufferTmp = windowBuffer
    
    ' Initialize counter
    Dim counterByteSaved As Long
    counterByteSaved = 0
    gap = 0
    func = Empty
    funcArg = Empty
    jump = 0
    mod_func = 0

    ' Slide window across the array
    Dim windowBufferLength As Long
    Dim SlidingWindowsLength As Long
    windowBufferLength = UBound(windowBufferTmp)
    SlidingWindowsLength = UBound(windowSliding)
    n = CInt(Application.WorksheetFunction.Ceiling(windowBufferLength / SlidingWindowsLength, 1))
    
    Dim i As Long
    Dim j As Long
    Dim match As Boolean
    Dim exitLoop As Boolean
    bbFlag = False
    beginFlag = False
    exitLoop = False
    For i = 1 To n
    
        ' Check for match
        match = True
        
        ' Pour toutes les valeur de la fenêtre glissante
        For j = 1 To SlidingWindowsLength
        
            ' Si on est en dehors de la fenêtre glissante, on arrête le boucle, la détection est finie
            If j > UBound(windowBufferTmp) Then exitLoop = True: Exit For
            
            ' Si les valeur ne concordent pas maintenant ou si nous avions détecté
            ' une non égalité en amont
            If CStr(windowBufferTmp(j)) <> CStr(windowSliding(j)) Or Not match Then
            
                ' On passe le flag match à false, il n'y a plus d'égalité
                match = False
                
                ' Si nous avions déjà commencé une détection, il faut calculer l'écart entre la case actuelle et l
                If Not beginFlag Then: gap = gap + 1
                
                ' On passe le flag exitLoop à True, la détection est finie
                exitLoop = True

            ' Si les valeur ne concordent pas
            ElseIf match Then
            
                ' On calcule le nombre de bytes compréssés
                counterByteSaved = counterByteSaved + 1
                
                ' Si nous n'avions pas commencé une détection, il faut calculer l'argument de la fonction
                ' C'est le gap mais modulo mod_func
                If Not beginFlag Then mod_func = mod_func + 1
            End If
        Next j
        
        If exitLoop Then Exit For ' exit the outer loop
        
        ' Si nous sommes dans le cas d'une détection
        If match Then
            
            ' Nous indiquons que nous avons commencé une détection
            beginFlag = True
            
            ' On retire les les valeurs détectées de la fenêtre glissante
            For j = 1 To SlidingWindowsLength
                windowBufferTmp = RemoveFirstElement(windowBufferTmp)
            Next j
        Else: Exit For
        End If

    Next i

    If gap + mod_func = 1 And counterByteSaved > 7 Then
        BytesSaved = counterByteSaved - 2
        func = "E8"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 2 Then
        BytesSaved = counterByteSaved - 2
        func = "E8"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
            
    ElseIf gap + mod_func = 3 Then
        BytesSaved = counterByteSaved - 2
        func = "E9"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
          
    ElseIf gap + mod_func = 4 Then
        BytesSaved = counterByteSaved - 2
        func = "E9"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
           
    ElseIf gap + mod_func = 5 Then
        BytesSaved = counterByteSaved - 2
        func = "EA"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 6 Then
        BytesSaved = counterByteSaved - 2
        func = "EA"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
                
    ElseIf gap + mod_func = 7 Then
        BytesSaved = counterByteSaved - 2
        func = "EB"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
          
    ElseIf gap + mod_func = 8 Then
        BytesSaved = counterByteSaved - 2
        func = "EB"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 9 Then
        BytesSaved = counterByteSaved - 2
        func = "EC"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 10 Then
        BytesSaved = counterByteSaved - 2
        func = "EC"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 11 Then
        BytesSaved = counterByteSaved - 2
        func = "ED"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 12 Then
        BytesSaved = counterByteSaved - 2
        func = "ED"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 13 Then
        BytesSaved = counterByteSaved - 2
        func = "EE"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 14 Then
        BytesSaved = counterByteSaved - 2
        func = "EE"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 15 Then
        BytesSaved = counterByteSaved - 2
        func = "EF"
        funcArg = FormatHexToBytes(ConvertDecToHex(counterByteSaved - 1))
        jump = counterByteSaved
        
    ElseIf gap + mod_func = 16 Then
        BytesSaved = counterByteSaved - 2
        func = "EF"
        funcArg = FormatHexToBytes(ConvertDecToHex(ConvertHexToDec(80) + counterByteSaved - 1))
        jump = counterByteSaved
    Else
        BytesSaved = 0

    End If

End Sub

Function SubArray(arr() As Variant, start As Long, finish As Long) As Variant
    EmptyArray = Array()

    ' Check if start or finish is less than 0
    If start <= 0 Or finish <= 0 Then
        SubArray = EmptyArray ' Return empty variant
        Exit Function
    End If
    
    Dim newArray() As Variant
    ReDim newArray(1 To finish - start + 1) As Variant
    Dim i As Long
    
    ' Ensure the finish index does not exceed the array's bounds
    If finish > UBound(arr) Then
        finish = UBound(arr)
    End If
    
    For i = start To finish
        newArray(i - start + 1) = arr(i)
    Next i
    
    SubArray = newArray
End Function


Function AddToArray(arr() As Variant, element As Variant) As Variant()
    If IsArrayEmpty(arr) Then
        ReDim arr(1 To 1) ' Resize the array to have one element
        arr(1) = element ' Assign the element to the first (and only) element of the array
    Else
        Dim currentSize As Long
        currentSize = UBound(arr) ' Get the current size of the array
        
        Dim newArray() As Variant
        ReDim newArray(1 To currentSize + 1) ' Create a new array with the increased size
        
        Dim i As Long
        For i = 1 To currentSize
            newArray(i) = arr(i) ' Copy existing elements to the new array
        Next i
        
        newArray(currentSize + 1) = element ' Assign the new element to the last element of the new array
        
        arr = newArray ' Assign the new array to the original array variable
    End If
    
    AddToArray = arr ' Return the modified array
End Function

Function IsArrayEmpty(arr() As Variant) As Boolean
    On Error GoTo ErrHandler
    If IsArray(arr) Then
        IsArrayEmpty = (UBound(arr) < LBound(arr))
    Else
        IsArrayEmpty = True
    End If
    Exit Function
ErrHandler:
    IsArrayEmpty = True
End Function

'Function GetIndexOfMaxValue(arr() As Variant) As Long
'    Dim maxIndex As Long
'    Dim maxValue As Variant
'    Dim i As Long
'
'    If IsArrayEmpty(arr) Then
'        GetIndexOfMaxValue = -1 ' Return -1 to indicate an empty array
'        Exit Function
'    End If
'
'    maxIndex = LBound(arr) ' Initialize the maximum index to the lower bound
'    maxValue = arr(maxIndex) ' Initialize the maximum value to the value at the lower bound
'
'    For i = LBound(arr) + 1 To UBound(arr)
'        If arr(i) > maxValue Then
'            maxIndex = i ' Update the maximum index
'            maxValue = arr(i) ' Update the maximum value
'        End If
'    Next i
'
'    GetIndexOfMaxValue = maxIndex ' Return the index of the maximum value
'End Function

Function RemoveFirstElement(arr() As Variant) As Variant
    If UBound(arr) - LBound(arr) = 0 Then
        RemoveFirstElement = Array()
    Else
        Dim newArr() As Variant
        Dim i As Long
    
        ' Redim newArray to size of original array minus 1
        ReDim newArr(LBound(arr) To UBound(arr) - 1)
    
        ' Copy values from second element onwards
        For i = LBound(newArr) To UBound(newArr)
            newArr(i) = arr(i + 1)
        Next i
    
        RemoveFirstElement = newArr
    End If
End Function

Public Function ConvertHexToDec(hexNumber As String) As Long
    ConvertHexToDec = CLng("&H" & hexNumber)
End Function

Public Function ConvertDecToHex(decNumber As Long) As String
    ConvertDecToHex = Hex(decNumber)
End Function

Function IncrementCursors(x_pos As Integer, y_pos As Integer, _
                            x_offset As Variant)
    Dim res(1) As Integer
    Dim i As Integer
    
    For i = 1 To Abs(x_offset)
        If x_offset > 0 Then
            x_pos = x_pos + 1
            If x_pos > Width_map Then
                x_pos = 1
                y_pos = y_pos + 1
            End If
        ElseIf x_offset < 0 Then
            x_pos = x_pos - 1
            If x_pos < 1 Then
                x_pos = Width_map
                y_pos = y_pos - 1
            End If
        End If
    Next i

End Function

Function FormatHexToBytes(hexValue As String) As String

    FormatHexToBytes = hexValue
    FormatHexToBytes = "'" & Format(hexValue, String(2, "0"))
    If Len(hexValue) = 1 Or _
        (hexValue <> "00" And Left(hexValue, 1) = "0") Then
        hexValue = "0" & Right(hexValue, 1)
    End If

    FormatHexToBytes = "'" & hexValue
End Function

'Function IncrementCursors(x_pos As Integer, y_pos As Integer,
'                            x_offset As Variant)
'
'    Dim i As Integer
'
'    For i = 0 To x_offset - 1
'        x_pos = x_pos + 1
'        If x_pos > Width_map - 1 Then
'            x_pos = 0
'            y_pos = y_pos + 1
'        End If
'    Next
'
'    IncrementCursors = result
'
'End Function


'        ' Dans le meilleur des cas, on trouve 127 valeurs identique, soit h(7F)
'        For k = i + 1 To i + ConvertHexToDec("7F")
'            If hexArray(i) = hexValue And k >= ConvertHexToDec("7F") Then
'                outputSheet.Cells(rowCounter, "A").value = hexValue
'                outputSheet.Cells(rowCounter, "B").value = "E8"
'                outputSheet.Cells(rowCounter, "C").value = "7F"
'                rowCounter = rowCounter + 1
'            ElseIf hexArray(i) = hexValue Then
'                hexCount = hexCount + 1
'            Else
'                If hexCount > 1 Then
'                    outputSheet.Cells(rowCounter, "A").value = hexValue
'                    If hexCount > 128 Then
'                        outputSheet.Cells(rowCounter, "B").value = "E8"'
'                        outputSheet.Cells(rowCounter, "C").value = Application.WorksheetFunction.Dec2Hex(hexCount - 1 + 128, 2)
'                    Else
'                        outputSheet.Cells(rowCounter, "B").value = "E8"
'                        outputSheet.Cells(rowCounter, "C").value = Application.WorksheetFunction.Dec2Hex(hexCount - 1, 2)
'                    End If<<s
'                    rowCounter = rowCounter + 1
'                Else
'                    outputSheet.Cells(rowCounter, "A").value = hexValue
'                    rowCounter = rowCounter + 1
'                End If
'                hexValue = hexArray(i)
'                hexCount = 1
'            End If
'        Next k

Function CreateSheetIfNotExist(sheetName As String) As Worksheet

    Dim ws As Worksheet

    On Error Resume Next
    Set ws = Worksheets(sheetName)
    On Error GoTo 0

    ' Check if sheet exists
    If ws Is Nothing Then
        ' If it doesn't exist, create it
        Set ws = Worksheets.Add(After:=Worksheets(Worksheets.Count))
        On Error Resume Next
        ws.Name = sheetName
        If Err.Number <> 0 Then
            Err.Clear
            MsgBox "Please provide a valid worksheet name."
            Exit Function
        End If
        On Error GoTo 0
    End If

    Set CreateSheetIfNotExist = ws

End Function

Function GetActiveSheetName() As String
    GetActiveSheetName = ActiveSheet.Name
End Function

Function FlattenArray(twoDimArray() As Variant) As Variant
    'Get the dimensions of the 2D array
    Dim nRows As Long, nCols As Long
    nRows = UBound(twoDimArray, 1) - LBound(twoDimArray, 1) + 1
    nCols = UBound(twoDimArray, 2) - LBound(twoDimArray, 2) + 1
    
    'Create an array to hold the flattened data
    Dim oneDimArray() As Variant
    ReDim oneDimArray(1 To nRows * nCols) As Variant

    'Flatten the 2D array into the 1D array
    Dim i As Long, j As Long, k As Long
    k = 1
    For i = LBound(twoDimArray, 1) To UBound(twoDimArray, 1)
        For j = LBound(twoDimArray, 2) To UBound(twoDimArray, 2)
            oneDimArray(k) = twoDimArray(i, j)
            k = k + 1
        Next j
    Next i
    
    'Return the 1D array
    FlattenArray = oneDimArray
End Function


Function CompleteCase(ByRef CalculsCase As CompressCalculsCaseWithoutProba, _
                        BytesSaved As Variant, _
                        gap As Variant, _
                        func As Variant, _
                        funcArg As Variant, _
                        jump As Variant) As CompressCalculsCaseWithoutProba
    CalculsCase.bytesSavedGeneral = BytesSaved
    CalculsCase.gapGeneral = gapGeneralArr
    CalculsCase.func = func
    CalculsCase.funcArg = funcArg
    CalculsCase.jump = jump
    CompleteCase = CalculsCase
End Function

