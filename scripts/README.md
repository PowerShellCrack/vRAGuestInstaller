# Extract vRA PowerShell script from appliance for these files:
curl.exe
openssl.exe
prepare_vra_template.bat
prepare_vra_template.ps1

Also need LGPO.exe for WSUS policy configurations

## Edit PowerShell Script
To get the PowerShell script to properly submit using Darwin's user-name and password modify these lines in prepare_vra_template.ps1

Line: 549
From 
	`if ($NonInteractive)`
to
	`
	if ($NonInteractive -and !$SoftwarePassword)
	`
The add a second Else statement in betweenthe else around line: 553
	`
	elseif($SoftwarePassword)
    {
        $SecurePassword = $SoftwarePassword | ConvertTo-SecureString -AsPlainText -Force
        $SoftwarePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword))
    }
	`
	
By doing this, you can now use the parameters at the very top of the script  in non-interactive mode. EG: 
`PowerShell.exe -noprofile -executionPolicy bypass -file "prepare_vra_template.ps1" -ApplianceHost vra-app.contoso.com -ManagerServiceHost vra-mgr.contoso.com -CloudProvider vSphere -SoftwareDomainUser .\Darwin -SoftwarePassword DarwinPassword -ManagerFingerprint "D4:2D:C5:BB:96:F0:A2:E1:69:96:12:C1:63:11:73:9B:FA:33:14:F4" -ApplianceFingerprint "D4:2D:C5:BB:96:F0:A2:E1:69:96:12:C1:63:11:73:9B:FA:33:14:F4" -Noninteractive -NoWindowsCheck`