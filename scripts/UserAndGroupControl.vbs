'-------------------------------------------------------------------------------------
' NAME: UserAndGroupAdmins.vbs
' DESCRIPTION: Script can set the password for a local administrator. 
' 			It can also add an Active Directory user or group to local Administrators group or Remote Desktop Users group 
'
' USAGE:	cscript userAndAdGroupAdmins.vbs /<arguments>:<value> /debug /RDSonly
'			cscript userAndAdGroupAdmins.vbs /<arguments>:<value> /debug:c:\windows\temp /logerrors:c:\windows\temp
'
' REQUIREMENTS: Update defaultTemplateAdmin to match template builtin accont
'
' ARGUMENTS:
' /password:<value> --> Set password to a specified local admin account. If no account defined, defaults to use variable:defaultTemplateAdmin
' /admin:<value> --> Used only if password is defined. If value not defined, defaults to use variable:defaultTemplateAdmin
' /user:<value> --> Adds AD user to local Administrators group; ignored if on workgroup
' /group:<value> --> Adds AD Group to local Administrators group; ignored if on workgroup
' /logerrors:<value> --> Only logs errors. Specify path to log directory, if no value default to script location. 
' /RDSonly --> Adds group or user to Remote Desktop Users group INSTEAD of local Administrators group
' /debug:<value> --> Specify path to log directory, if no value default to script location. USE ONLY FOR DEBUGGING! Password will be in clear text
'-------------------------------------------------------------------------------------

Option Explicit
' Contant variables
CONST defaultTemplateAdmin = "xadmin"
CONST ADS_UF_DONT_EXPIRE_PASSWD = &H10000

'Declare variables
Dim objFSO,objWshNet,strComputerName,colNamedArguments
Dim objWMISvc,colItems,strComputerDomain,isOnDomain,objItem
Dim boolFoundAdmin

'Load File object for logging
Set objFSO = CreateObject("Scripting.FileSystemObject")

'Load System network object to grab system information
Set objWshNet = CreateObject("WScript.Network")
strComputerName = objWshNet.ComputerName

'SET NAMED ARGUMENTS
Set colNamedArguments = Wscript.Arguments.Named

'ARGUMENT CHECK
if WScript.Arguments.Count = 0 then
	WScript.echo "No Arguments specified, unable to run script..."
	WScript.quit
else
	Trace32Log "VERBOSE: Script started",0
end if

'Check if system is on the domain or workgroup
Set objWMISvc = GetObject( "winmgmts:\\.\root\cimv2" )
Set colItems = objWMISvc.ExecQuery( "Select * from Win32_ComputerSystem", , 48 )
For Each objItem in colItems
	strComputerDomain = objItem.Domain
	If objItem.PartOfDomain Then
		Trace32Log "DOMAIN: " & strComputerName & " is joined to the Domain: " & strComputerDomain,1
		isOnDomain = True
	Else
		Trace32Log "WORKGROUP: " & strComputerName & " is on a workgroup: ",1
		isOnDomain = False
	End If
Next

'If password argument specified; change the local admin password 
If colNamedArguments.Exists("password") Then
	Dim argLocalAdmin
	Dim argAdminPwd
	Dim objAdmin

	argAdminPwd = colNamedArguments.Item("password")
	'Make sure value is not empty
	If argAdminPwd = "" Then
		Trace32Log "ARGUMENT: Password argument is null, skipping....",1
	Else
		Trace32Log "ARGUMENT: Password argument value is: " & argAdminPwd,1
		
		'If admin argument was found, use that, otherwise default to xadmin
		If colNamedArguments.Exists("admin") AND colNamedArguments.Item("admin") <> "" Then
			argLocalAdmin = colNamedArguments.Item("admin")
			Trace32Log "ARGUMENT: Admin argument value is: " & argLocalAdmin,1
		Else
			argLocalAdmin = defaultTemplateAdmin
			Trace32Log "ARGUMENT: Admin argument defaulted to: " & argLocalAdmin,1
		End If

		on error resume next
		boolFoundAdmin = False
		Set objAdmin = GetObject("WinNT://" & strComputerName & "/" & argLocalAdmin & ",user")
		If Err.Number <> 0 Then
			  Trace32Log "ERROR: Unable to connect to " & strComputerName & " or account doesn't exist: " & Err.Number & ": " & Err.Description,3
			Err.Clear
			'try using the defaultTemplateAdmin instead 
			argLocalAdmin = defaultTemplateAdmin
			  Trace32Log "RETRY: Reverting to defaultTemplateAdmin value: " & argLocalAdmin,3
			Set objAdmin = GetObject("WinNT://" & strComputerName & "/" & argLocalAdmin & ",user")
			If Err.Number <> 0 Then
				  Trace32Log "ERROR: defaultTemplateAdmin account doesn't exist: " & Err.Number & ": " & Err.Description,3
				Err.Clear
			Else
				boolFoundAdmin = True 
			End If
		Else
			boolFoundAdmin = True 
		End If
			
		If boolFoundAdmin Then
			Trace32Log "VERBOSE: Admin account [" & argLocalAdmin & "] was found on:" & strComputerName & ", attempting to change password...",1
			' Set the password for the account
			objAdmin.SetPassword argAdminPwd
			
			If Not objAdmin.userFlags Or ADS_UF_DONT_EXPIRE_PASSWD Then
				' Set Local admin to never expire
				Trace32Log "VERBOSE: Admin account [" & argLocalAdmin & "] was found on:" & strComputerName & ", attempting to set password to never expire...",1
				objAdmin.userFlags = (objAdmin.userFlags Or ADS_UF_DONT_EXPIRE_PASSWD)
			End If
			
			'save
			objAdmin.SetInfo
			If Err.Number <> 0 Then
				  Trace32Log "ERROR: Unable to set password for [" & argLocalAdmin & "] on [" & strComputerName & "]: " & Err.Number & ": " & Err.Description,3
				Err.Clear
			Else
				Trace32Log "SUCCESS: Password set for [" & argLocalAdmin & "]on [" & strComputerName & "]",1
			End If
		End If
		
	End If
End If


If colNamedArguments.Exists("user") AND isOnDomain Then
	Dim argUserUPN
	Dim userName
	Dim userDomain
	Dim clipped
	Dim objDomainUser
	Dim removefqdn
	Dim mem
	
	argUserUPN = colNamedArguments.Item("user")
	'Make sure value is not empty
	If argUserUPN = "" Then
		Trace32Log "ARGUMENT: User argument is null, skipping....",1
	Else
		Trace32Log "ARGUMENT: User argument value is: " & argUserUPN,1

		'Find user name if like: username@domain.com
		If InStr(argUserUPN,"@") Then
			clipped = Split(argUserUPN,"@")
			userName = clipped(0)
			removefqdn = Split(clipped(0),".")
			userDomain = removefqdn(0)

		'Find user name if like: domain.com\username
		Elseif InStr (argUserUPN,"\") Then
			clipped = Split(argUserUPN,"\")
			userName = clipped(1)
			removefqdn = Split(clipped(0),".")
			userDomain = removefqdn(0)
		End If
		
		If colNamedArguments.Exists("RDSonly") Then
			Set objLocalGroup = GetObject("WinNT://" & strComputerName & "/Remote Desktop Users,group")
		Else
			Set objLocalGroup = GetObject("WinNT://" & strComputerName & "/Administrators,group")
		End If
		
		For Each mem In objLocalGroup.Members
			Trace32Log "VERBOSE: " & mem.name & " is a member of the " & objLocalGroup.name & " group.: " & mem.ADsPath,1
		Next
		
		Set objDomainUser = GetObject("WinNT://" & userDomain & "/" & userName & ",user")
		
		'check if user is already an administrator; if not , add them to the local administrators group
		If Not objLocalGroup.IsMember(objDomainUser.ADsPath) Then
			objLocalGroup.Add(objDomainUser.ADsPath)
			If Err.Number = 450 OR Err.Number = 0 Then
				Trace32Log "SUCCESS: User [" & userDomain & "\" & userName & "] added to [" & strComputerName & "] local administrators group",1
			Else
				Trace32Log "ERROR: Unable to add [" & userDomain & "\" & userName & "] user to [" & strComputerName & "]: " & Err.Number & ": " & Err.Description,3
			End If
			Err.Clear
		Else
			Trace32Log "FOUND: User [" & userDomain & "\" & userName & "] already member of local administrators, nothing done.",1
		End If
		
		Set objLocalGroup = Nothing
		Set objDomainUser = Nothing
	End If
End If


If colNamedArguments.Exists("group") AND isOnDomain Then
	Dim argGroupName
	Dim objLocalGroup
	Dim objRDPGroup
	Dim groupName
	Dim groupDomain
	Dim objDomainGroup
	
	argGroupName = colNamedArguments.Item("group")
	'Make sure value is not empty
	If argGroupName = "" Then
		Trace32Log "ARGUMENT: Group argument is null, skipping....",1
	Else
		Trace32Log "ARGUMENT: Group argument value is: " & argGroupName,1
		
		'Find group if like: domain.com\group
		If InStr (argGroupName,"\") Then
			clipped = Split(argGroupName,"\")
			groupName = clipped(1)
			removefqdn = Split(clipped(0),".")
			groupDomain = removefqdn(0)
		End If
		
		If colNamedArguments.Exists("RDSonly") Then
			Set objLocalGroup = GetObject("WinNT://" & strComputerName & "/Remote Desktop Users,group")
		Else
			Set objLocalGroup = GetObject("WinNT://" & strComputerName & "/Administrators,group")
		End If
		
		For Each mem In objLocalGroup.Members
			Trace32Log "VERBOSE: " & mem.name & " is a member of the " & objLocalGroup.name & " group.: " & mem.ADsPath,1
		Next
		
		Set objDomainGroup = GetObject("WinNT://" & groupDomain & "/" & groupName)
		
		'check if user is already an administrator; if not , add them to the local administrators group
		If Not objLocalGroup.IsMember(objDomainGroup.ADsPath) Then
			objLocalGroup.Add(objDomainGroup.ADsPath)
			If Err.Number = 450 OR Err.Number = 0 Then
				Trace32Log "SUCCESS: Group [" & groupDomain & "\" & groupName & "] added to [" & strComputerName & "] local administrators group.",1
			Else
				Trace32Log "ERROR: Unable to add [" & groupDomain & "\" & groupName & "] group to [" & strComputerName & "]: " & Err.Number & ": " & Err.Description,3
			End If
			Err.Clear
		Else
			Trace32Log "FOUND: Group [" & groupDomain & "\" & groupName & "] already member of local administrators, nothing done.",1
		End If
		
		Set objLocalGroup = Nothing
		Set objDomainGroup = Nothing
	End If
End If

Trace32Log "VERBOSE: Script completed",1

''''''''' FUNCTIONS '''''''''''''''
Sub Trace32Log(LogTxt,ErrType) 
	'*********************************************************** 
	' Source: https://gallery.technet.microsoft.com/scriptcenter/41f111c0-e1fb-4908-b31f-2e3b37a36910
	' Write trace32.exe compatible log file (SMS/SCCM environment). 
	' useful in VBS and HTA 
	' logfile - syntax (SMS Trace) 
	' <![LOG[...]LOG]!> 
	' < 
	'    time="04:00:54.309+-60" 
	'    date="03-14-2008" 
	'    component="SrcUpdateMgr" 
	'    context="" 
	'    type="0" 
	'    thread="1812" 
	'    file="productpackage.cpp:97" 
	' > 
	' 
	'    "context="    will not display 
	'    type="0"    Trace32Log-procedure delete logfile an create new logfile 
	'    type="1"    display as normally line 
	'    type="2"    display as yellow line / warn 
	'    type="3"    display as red line / error 
	'    type="F"    display as red line / error 
	'	 type="V"    display as normally line; only ran when verbose configured
	'    "thread="    number, display as "Tread:", example "Tread: 33 (0x21)" 
	'    "file="        diplay as "Source:" 
	' 
 
	Dim sScriptDir, sLogFilename
	
	Dim Tst 
	Dim argErLogDir,argDgLogDir,sLogFilePath,sLogOut
	DIm boolEnableLogging
	
	sScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
	sLogFilename = objFSO.getbasename(Wscript.ScriptName)
	 
	' enumerate milliseconds 
	' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
	Tst = Timer()               ' timer() in USA: 1234.22; dot separation 
	Tst = Replace( Tst, "," , ".")        ' timer() in german: 23454,12; comma separation 
	If InStr( Tst, "." ) = 0 Then Tst = Tst & ".000" 
	Tst = Mid( Tst, InStr( Tst, "." ), 4 ) 
	If Len( Tst ) < 3 Then Tst = Tst & "0" 
 
	' enumerate time zone 
	' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
	Dim AktDMTF : Set AktDMTF = CreateObject("WbemScripting.SWbemDateTime") 
	AktDMTF.SetVarDate Now(), True : Tst = Tst & Mid( AktDMTF, 22 ) ' : MsgBox Tst, , "099 :: " 
	' MsgBox "AktDMTF: '" & AktDMTF & "'", , "100 :: " 
	Set AktDMTF = nothing 
	
	'Build Log file
	LogTxt = "<![LOG[" & LogTxt & "]LOG]!>" 
	LogTxt = LogTxt & "<" 
	LogTxt = LogTxt & "time=""" & Hour( Time() ) & ":" & _ 
		Minute( Time() ) & ":" & Second( Time() ) & Tst & """ " 
	LogTxt = LogTxt & "date=""" & Month( Date() ) & "-" & _ 
		Day( Date() ) & "-" & Year( Date() ) & """ " 
	LogTxt = LogTxt & "component=""" & sLogFilename & """ " 
	LogTxt = LogTxt & "context="""" " 
	LogTxt = LogTxt & "type=""" & ErrType & """ " 
	LogTxt = LogTxt & "thread=""0"" " 
	LogTxt = LogTxt & "file=""log"" " 
	LogTxt = LogTxt & ">" 
 
			Tst = 8 ' ForAppending; append file 
	If ErrType = 0 Then    Tst = 2 ' ForWriting; new file 
	If ErrType = "V" Then    Tst = 1 ' ForWriting; verbose only
	
	If colNamedArguments.Exists("debug") Then
		boolEnableLogging = True
		argDgLogDir = colNamedArguments.Item("debug")
		'If path is not specified build location of log
		If argDgLogDir = "" Then	
			sLogFilePath = sScriptDir & "\" & sLogFilename & "_debug.log"
		Else
			sLogFilePath = argDgLogDir & "\" & sLogFilename & "_debug.log"
		End If

	ElseIf colNamedArguments.Exists("logerrors") AND (ErrType = 3 OR ErrType = "F") Then
		boolEnableLogging = True
		argErLogDir = colNamedArguments.Item("logerrors")
		'If path is not specified build location of log
		If argErLogDir = "" Then
			sLogFilePath = sScriptDir & "\" & sLogFilename & "_errors.log"
		Else
			sLogFilePath = argErLogDir & "\" & sLogFilename & "_errors.log"
		End If
		
	Else
		boolEnableLogging = False
	End If
	
	If boolEnableLogging Then
		Set sLogOut = objFSO.OpenTextFile(sLogFilePath, Tst, true)
		If     LogTxt = vbCRLF Then sLogOut.WriteLine ( LogTxt ) 
		If not LogTxt = vbCRLF Then sLogOut.WriteLine ( LogTxt )
		sLogOut.Close
		Set sLogOut = Nothing
	End If

End Sub ' Trace32Log( LogTxt, ErrType )


Set objFSO = Nothing 