REM  *****  BASIC  *****

Sub test1()
	Dim	Sheet
	Dim F50
    Dim sFilename As String 
    Dim oSourceSpreadsheet As Variant 
        sFilename = ConvertToURL("/home/jenov/tmp/inv_2_lo.xlsx")
        If Not FileExists(sFilename) Then 
            MsgBox("File not found!")
            Exit Sub 
        EndIf 
        
        GlobalScope.BasicLibraries.loadLibrary("Tools")
        oSourceSpreadsheet = OpenDocument(sFilename, Array())
        If IsEmpty(oSourceSpreadsheet) Then 
            MsgBox("The file may be open in another application",0,"Failed to load file")
            Exit Sub 
        EndIf 
    	Sheet = thiscomponent.sheets.getByName("Rating Ex 1 (2)")
    	F50 = Sheet.getCellRangeByName( "F50" )
    	sFNAME = ConvertToURL("/home/jenov/tmp/xxx.txt")
    	OPEN sFNAME for OUTPUT ACCESS WRITE AS #1
    	PRINT #1 F50.string
    	CLOSE #1
    	RtnCode = MsgBox( F50.string ,0, "Cell Value" )
    	Wait 1000
    End Sub 
