' ------------------------------------------------
' Name : Data Package System V0.4
' Date : (C)2025
' Site:https://github.com/BlackCreepyCat
' -----------------------------------------------
SuperStrict

' -------------------
' Required modules
' -------------------
Import brl.max2d
Import brl.pixmap
Import brl.standardio
Import brl.filesystem
Import brl.bank
Import brl.audio  ' Pour les sons
Import Archive.ZLib

' ------------------------------------
' Constants for data types
' ------------------------------------
Const TYPE_FILE:Int = 0    ' Raw file
Const TYPE_TEXT:Int = 1    ' Text
Const TYPE_IMAGE:Int = 2   ' Image (Pixmap)
Const TYPE_STRING:Int = 3  ' String (comme une variable)
Const TYPE_INT:Int = 4     ' Integer
Const TYPE_FLOAT:Int = 5   ' Float
Const TYPE_SOUND:Int = 6   ' Sound

Const HEADER_STRING:String = "PAK1.0 (C)2025 By CreepyCat"

' Structure pour un élément dans l'index
Type TPakEntry
    Field dataType:Int      ' Type of data
    Field name:String       ' Name of the element (with relative path)
    Field offset:Long       ' Position in the file where compressed data starts
    Field fullSize:ULongInt ' Uncompressed size of the data
    Field packedSize:ULongInt ' Compressed size of the data
    Field packedData:TBank  ' Temporary storage for compressed data
End Type

' ----------------------------
' Class to manage the package
' ----------------------------
Type TPakManager
    Global entries:TList = CreateList()  ' List to store all entries

    ' -------------------------
    ' Add a file to the package
    ' -------------------------
    Function AddFile(filename:String, basePath:String)
        If FileType(filename) <> 1 Then Return
        Local file:TStream = ReadFile(filename)
        Local fullSize:ULongInt = FileSize(filename)
        If fullSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "File too large for TBank.Read: " + filename
        If fullSize > $7FFFFFFF Then RuntimeError "File too large for CreateBank: " + filename
        
        Local bank:TBank = CreateBank(Int(fullSize))
        bank.Read(file, 0, Long(fullSize))
        CloseFile(file)

        Local entry:TPakEntry = New TPakEntry
        entry.dataType = TYPE_FILE
        entry.name = filename.Replace(basePath + "/", "")
        entry.fullSize = fullSize
        entry.packedData = Pak_CompressBank(bank)
        entry.packedSize = entry.packedData.Size()
        entries.AddLast(entry)

        Print "Added file: " + entry.name + " (" + entry.fullSize + " -> " + entry.packedSize + " bytes)"
    End Function

    ' -----------------------
    ' Add text to the package
    ' -----------------------
    Function AddText(text:String, name:String)
        Local fullSize:ULongInt = text.Length
        If fullSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "Text too large for TBank.Read: " + name
        If fullSize > $7FFFFFFF Then RuntimeError "Text too large for CreateBank: " + name
        
        Local bank:TBank = CreateBank(Int(fullSize))
        Local textBuf:Byte Ptr = text.ToCString()
        MemCopy(bank.Buf(), textBuf, Size_T(fullSize))
        MemFree textBuf

        Local entry:TPakEntry = New TPakEntry
        entry.dataType = TYPE_TEXT
        entry.name = name
        entry.fullSize = fullSize
        entry.packedData = Pak_CompressBank(bank)
        entry.packedSize = entry.packedData.Size()
        entries.AddLast(entry)

        Print "Added text: " + entry.name + " (" + entry.fullSize + " -> " + entry.packedSize + " bytes)"
    End Function

    ' ---------------------------
    ' Add an image to the package
    ' ---------------------------
    Function AddImage(pixmap:TPixmap, name:String)
        Local bufferSize:ULongInt = pixmap.Width * pixmap.Height * BytesPerPixel[pixmap.Format]
        Local fullSize:ULongInt = 12 + bufferSize
        If fullSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "Image too large for TBank.Read: " + name
        If fullSize > $7FFFFFFF Then RuntimeError "Image too large for CreateBank: " + name
        
        Local bank:TBank = CreateBank(Int(fullSize))
        bank.PokeInt(0, pixmap.Width)
        bank.PokeInt(4, pixmap.Height)
        bank.PokeInt(8, pixmap.Format)
        MemCopy(bank.Buf() + 12, pixmap.pixels, Size_T(bufferSize))

        Local entry:TPakEntry = New TPakEntry
        entry.dataType = TYPE_IMAGE
        entry.name = name
        entry.fullSize = fullSize
        entry.packedData = Pak_CompressBank(bank)
        entry.packedSize = entry.packedData.Size()
        entries.AddLast(entry)

        Print "Added image: " + entry.name + " (" + entry.fullSize + " -> " + entry.packedSize + " bytes)"
    End Function

    ' ---------------------------
    ' Add a string to the package
    ' ---------------------------
    Function AddString(value:String, name:String)
        Local fullSize:ULongInt = value.Length
        If fullSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "String too large for TBank.Read: " + name
        If fullSize > $7FFFFFFF Then RuntimeError "String too large for CreateBank: " + name
        
        Local bank:TBank = CreateBank(Int(fullSize))
        Local valueBuf:Byte Ptr = value.ToCString()
        MemCopy(bank.Buf(), valueBuf, Size_T(fullSize))
        MemFree valueBuf

        Local entry:TPakEntry = New TPakEntry
        entry.dataType = TYPE_STRING
        entry.name = name
        entry.fullSize = fullSize
        entry.packedData = Pak_CompressBank(bank)
        entry.packedSize = entry.packedData.Size()
        entries.AddLast(entry)

        Print "Added string: " + entry.name + " (" + entry.fullSize + " -> " + entry.packedSize + " bytes)"
    End Function

    ' ---------------------------
    ' Add an int to the package
    ' ---------------------------
    Function AddInt(value:Int, name:String)
        Local fullSize:ULongInt = 4
        Local bank:TBank = CreateBank(Int(fullSize))
        bank.PokeInt(0, value)

        Local entry:TPakEntry = New TPakEntry
        entry.dataType = TYPE_INT
        entry.name = name
        entry.fullSize = fullSize
        entry.packedData = Pak_CompressBank(bank)
        entry.packedSize = entry.packedData.Size()
        entries.AddLast(entry)

        Print "Added int: " + entry.name + " (" + entry.fullSize + " -> " + entry.packedSize + " bytes)"
    End Function

    ' ---------------------------
    ' Add a float to the package
    ' ---------------------------
    Function AddFloat(value:Float, name:String)
        Local fullSize:ULongInt = 4
        Local bank:TBank = CreateBank(Int(fullSize))
        bank.PokeFloat(0, value)

        Local entry:TPakEntry = New TPakEntry
        entry.dataType = TYPE_FLOAT
        entry.name = name
        entry.fullSize = fullSize
        entry.packedData = Pak_CompressBank(bank)
        entry.packedSize = entry.packedData.Size()
        entries.AddLast(entry)

        Print "Added float: " + entry.name + " (" + entry.fullSize + " -> " + entry.packedSize + " bytes)"
    End Function

    ' ---------------------------
    ' Add a sound to the package
    ' ---------------------------
    Function AddSound(filename:String, name:String)
        If FileType(filename) <> 1 Then RuntimeError "Sound file not found: " + filename
        Local file:TStream = ReadFile(filename)
        Local fullSize:ULongInt = FileSize(filename)
        If fullSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "Sound too large for TBank.Read: " + filename
        If fullSize > $7FFFFFFF Then RuntimeError "Sound too large for CreateBank: " + filename
        
        Local bank:TBank = CreateBank(Int(fullSize))
        bank.Read(file, 0, Long(fullSize))
        CloseFile(file)

        Local entry:TPakEntry = New TPakEntry
        entry.dataType = TYPE_SOUND
        entry.name = name
        entry.fullSize = fullSize
        entry.packedData = Pak_CompressBank(bank)
        entry.packedSize = entry.packedData.Size()
        entries.AddLast(entry)

        Print "Added sound: " + entry.name + " (" + entry.fullSize + " -> " + entry.packedSize + " bytes)"
    End Function

    ' ------------------------------
    ' Add all files from a directory
    ' ------------------------------
    Function AddDirectory(dirPath:String, basePath:String = "")
        If basePath = "" Then basePath = dirPath
        
        Local dir:Byte Ptr = ReadDir(dirPath)
        If Not dir Then RuntimeError "Cannot open directory: " + dirPath

        Local file:String
        
        Repeat
            file = NextFile(dir)
            If file = "" Then Exit
            If file = "." Or file = ".." Then Continue
            
            Local fullPath:String = dirPath + "/" + file
            
            If FileType(fullPath) = 1 Then
                AddFile(fullPath, basePath)
            ElseIf FileType(fullPath) = 2 Then
                AddDirectory(fullPath, basePath)
            EndIf
        Forever
        
        CloseDir(dir)
        Print "Added all files from directory: " + dirPath
    End Function

    ' -----------------------
    ' Create the package file
    ' -----------------------
    Function CreatePak(filename:String)
        Local pakStream:TStream = WriteFile(filename)
        If Not pakStream Then RuntimeError "Cannot create package: " + filename

        pakStream.WriteLine(HEADER_STRING)
        pakStream.WriteInt(entries.Count())

        Local indexSize:Long = 0
        For Local entry:TPakEntry = EachIn entries
            indexSize :+ 4 + 4 + entry.name.Length + 8 + 8 + 8
        Next

        Local dataOffset:Long = pakStream.Pos() + indexSize
        Local indexOffset:Long = pakStream.Pos()
        
        For Local entry:TPakEntry = EachIn entries
            pakStream.WriteInt(entry.dataType)
            pakStream.WriteInt(entry.name.Length)
            pakStream.WriteString(entry.name)
            pakStream.WriteLong(0)
            pakStream.WriteLong(Long(entry.fullSize))
            pakStream.WriteLong(Long(entry.packedSize))
        Next

        Local currentOffset:Long = dataOffset
        For Local entry:TPakEntry = EachIn entries
            entry.offset = currentOffset
            pakStream.WriteBytes(entry.packedData.Buf(), Long(entry.packedSize))
            currentOffset :+ entry.packedSize
        Next

        SeekStream(pakStream, indexOffset)
        For Local entry:TPakEntry = EachIn entries
            pakStream.WriteInt(entry.dataType)
            pakStream.WriteInt(entry.name.Length)
            pakStream.WriteString(entry.name)
            pakStream.WriteLong(entry.offset)
            pakStream.WriteLong(Long(entry.fullSize))
            pakStream.WriteLong(Long(entry.packedSize))
        Next

        CloseFile(pakStream)
        Print "Package created: " + filename + " (" + FileSize(filename) + " bytes)"
    End Function

    ' ---------------------
    ' List package contents
    ' ---------------------
    Function ListPak(filename:String)
        Local pakStream:TStream = ReadFile(filename)
        If Not pakStream Then RuntimeError "Cannot open package: " + filename

        Local header:String = pakStream.ReadLine()
        If header <> HEADER_STRING Then RuntimeError "Invalid package format"

        Local numEntries:Int = pakStream.ReadInt()
        Print "Contents of package " + filename + " (" + numEntries + " elements):"
        
        For Local i:Int = 0 Until numEntries
            Local entry:TPakEntry = New TPakEntry
            entry.dataType = pakStream.ReadInt()
            Local nameLength:Int = pakStream.ReadInt()
            entry.name = pakStream.ReadString(nameLength)
            entry.offset = pakStream.ReadLong()
            entry.fullSize = pakStream.ReadLong()
            entry.packedSize = pakStream.ReadLong()
            Print " - " + entry.name + " (type=" + entry.dataType + ", full=" + entry.fullSize + ", packed=" + entry.packedSize + ", offset=" + entry.offset + ")"
        Next

        CloseFile(pakStream)
    End Function

    ' -----------------------------
    ' Load an item from the package
    ' -----------------------------
    Function LoadItem:Object(filename:String, itemName:String)
        Local pakStream:TStream = ReadFile(filename)
        If Not pakStream Then Return Null

        Local header:String = pakStream.ReadLine()
        If header <> HEADER_STRING Then RuntimeError "Invalid package format"

        Local numEntries:Int = pakStream.ReadInt()
        Local targetEntry:TPakEntry
        
        For Local i:Int = 0 Until numEntries
            Local entry:TPakEntry = New TPakEntry
            entry.dataType = pakStream.ReadInt()
            Local nameLength:Int = pakStream.ReadInt()
            entry.name = pakStream.ReadString(nameLength)
            entry.offset = pakStream.ReadLong()
            entry.fullSize = pakStream.ReadLong()
            entry.packedSize = pakStream.ReadLong()
            If entry.name = itemName Then targetEntry = entry ; Exit
        Next

        If Not targetEntry Then
            CloseFile(pakStream)
            Print "Item not found in package: " + itemName
            Return Null
        EndIf

        SeekStream(pakStream, targetEntry.offset)
        If targetEntry.packedSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "Compressed data too large for TBank.Read: " + itemName
        If targetEntry.packedSize > $7FFFFFFF Then RuntimeError "Compressed data too large for CreateBank: " + itemName
        
        Local packedBank:TBank = CreateBank(Int(targetEntry.packedSize))
        packedBank.Read(pakStream, 0, Long(targetEntry.packedSize))
        Local bank:TBank = Pak_UncompressBank(packedBank)
        CloseFile(pakStream)

        Select targetEntry.dataType
            Case TYPE_FILE
                Local stream:TBankStream = CreateBankStream(bank)
                Return stream
            Case TYPE_TEXT
                Return String.FromBytes(bank.Buf(), bank.Size())
            Case TYPE_IMAGE
                Local width:Int = bank.PeekInt(0)
                Local height:Int = bank.PeekInt(4)
                Local format:Int = bank.PeekInt(8)
                If format < 1 Or format > 6 Then
                    Print "Invalid format for " + itemName + ": " + format
                    Return Null
                EndIf
                Local pixmap:TPixmap = CreatePixmap(width, height, format)
                If Not pixmap Then Return Null
                MemCopy(pixmap.pixels, bank.Buf() + 12, Size_T(bank.Size() - 12))
                Return LoadImage(pixmap)
            Case TYPE_STRING
                Return String.FromBytes(bank.Buf(), bank.Size())
            Case TYPE_INT
                Return String(bank.PeekInt(0))
            Case TYPE_FLOAT
                Return String(bank.PeekFloat(0))
            Case TYPE_SOUND
                Local stream:TBankStream = CreateBankStream(bank)
                SeekStream(stream, 0)  ' S'assurer que le curseur est au début
                Local sound:TSound = LoadSound(stream)
                If Not sound Then
                    Print "Failed to load sound from stream: " + itemName
                    ' Pour debug : sauvegarder le flux décompressé dans un fichier temporaire
                    Local tempFile:TStream = WriteFile("temp_" + itemName)
                    bank.Save(tempFile)
                    CloseFile(tempFile)
                    Print "Saved decompressed sound to temp_" + itemName + " for debugging"
                EndIf
                Return sound
        End Select

        Return Null
    End Function
End Type

' -----------------------
' Compress a bank of data
' -----------------------
Function Pak_CompressBank:TBank(bank:TBank)
    Local size:ULongInt = bank.Size()
    Local outSize:ULongInt = size + size / 10 + 32
    If outSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "Estimated compressed size too large for compress2"
    If outSize > $7FFFFFFF Then RuntimeError "Estimated compressed size too large for CreateBank"
    
    Local out:TBank = TBank.Create(Int(outSize))
    compress2(out.Buf() + 8, outSize, bank.Buf(), size, 9)
    out.PokeLong(0, Long(size))
    out.Resize(Int(outSize + 8))
    
    Return out
End Function

' -------------------------
' Decompress a bank of data
' -------------------------
Function Pak_UncompressBank:TBank(bank:TBank)
    Local outSize:ULongInt = bank.PeekLong(0)
    If outSize > $7FFFFFFFFFFFFFFF:ULongInt Then RuntimeError "Decompressed size too large for uncompress"
    If outSize > $7FFFFFFF Then RuntimeError "Decompressed size too large for CreateBank"
    
    Local out:TBank = TBank.Create(Int(outSize))
    uncompress(out.Buf(), outSize, bank.Buf() + 8, ULongInt(bank.Size() - 8))
    Return out
End Function

' -----------------------------------------
' Main function to test the package manager
' -----------------------------------------
Function Main()
    Graphics(800, 600)

    ' -------------------------------
    ' Create and populate the package
    ' -------------------------------
    Local pak:TPakManager = New TPakManager
    pak.AddDirectory("directory")
    pak.AddText("Hello world", "Salutation.txt")
    
    Local pixmap:TPixmap = LoadPixmap("Node_Icon_Bluetooth.png")
    If pixmap Then
        pak.AddImage(pixmap, "image_directe")
    EndIf
    
    pak.AddString("CreepyCat", "PlayerName")
    pak.AddInt(42, "PlayerLevel")
    pak.AddFloat(3.14159, "PlayerSpeed")
    pak.AddSound("Directory/Dreamkid.wav", "TestSound")
    
    pak.CreatePak("test.pak")

    ' -------------
    ' List contents
    ' -------------
    TPakManager.ListPak("test.pak")

    ' ---------------------------
    ' Load items from the package
    ' ---------------------------
    Local fileStream:TBankStream = TBankStream(TPakManager.LoadItem("test.pak", "Test/Node_Icon_App.png"))
    Local pixmapFromPak:TPixmap
    If fileStream Then
        pixmapFromPak = LoadPixmap(fileStream)
    EndIf
    
    Local text:String = String(TPakManager.LoadItem("test.pak", "Salutation.txt"))
    Local image:TImage
    If pixmapFromPak Then
        image = LoadImage(pixmapFromPak)
    EndIf
    
    Local loadedString:String = String(TPakManager.LoadItem("test.pak", "PlayerName"))
    Local loadedInt:Int = Int(String(TPakManager.LoadItem("test.pak", "PlayerLevel")))
    Local loadedFloat:Float = Float(String(TPakManager.LoadItem("test.pak", "PlayerSpeed")))
    Local loadedSound:TSound = TSound(TPakManager.LoadItem("test.pak", "TestSound"))

    Print "Loaded text: " + text
    If image Then
        Print "Image loaded: OK"
    Else
        Print "Image loading error"
    EndIf
    Print "Loaded string: " + loadedString
    Print "Loaded int: " + loadedInt
    Print "Loaded float: " + loadedFloat
    
    If loadedSound Then
        Print "Sound loaded: OK"
    Else
        Print "Sound loading error"
    EndIf

    ' Jouer le son si chargé
    If loadedSound Then
        PlaySound(loadedSound)
    Else
        Print "Impossible de jouer le son"
    EndIf

    ' ------------
    ' Display loop
    ' ------------
    While Not KeyHit(KEY_ESCAPE)
        Cls
        DrawText("Text: " + text, 10, 10)
        If image Then DrawImage(image, 150, 50)
        DrawText("String: " + loadedString, 10, 100)
        DrawText("Int: " + loadedInt, 10, 120)
        DrawText("Float: " + loadedFloat, 10, 140)
        
        If loadedSound Then
            DrawText("Sound: Playing 'TestSound'", 10, 160)
        Else
            DrawText("Sound: Not loaded", 10, 160)
        EndIf
        
        DrawText("Press ESC to quit", 10, 580)
        Flip
    Wend

    EndGraphics()
End Function

Main()
