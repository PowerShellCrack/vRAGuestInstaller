<#Script: WSUS.ps1

Information: This script was adapated from the WUA_SearchDownloadInstall.vbs VBScript from Microsoft.  It uses the
                Microsoft.Update.Session COM object to query a WSUS server, find applicable updates, and install them.

WSUS.ps1 is a little less verbose about what it is doing when compared to the orginal VBScript.  The
lines exist in the code below to show the same information as the original but are just commented out.


WSUS.ps1 can automatically install applicable updates by passing a Y to the script.  The default
behavior is to ask whether or not to install the new updates.

Syntax:  .\WSUS.ps1 -Install -Reboot
    Where [Install] is optional
    Whether or not to install the updates automatically.  If Null, the user will be prompted.

    Where [Reboot] is optional
    If updates require a reboot, whether or not to reboot automatically.  If Null, the user will
    be prompted.
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
    [Alias('Update')]
	[switch]$Install,
    [Parameter(Mandatory=$false)]
    [Alias('Restart')]
	[switch]$Reboot
)

Try{
    $UpdateSession = New-Object -Com Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
}Catch{
    Write-Host("Unable to connected to WSUS object...") -Fore Red
    exit -1
}

Write-Host("Searching for applicable updates...") -Fore Green
 
$SearchResult = $UpdateSearcher.Search("IsInstalled=0 and Type='Software'")
 
Write-Host("")
Write-Host("List of applicable items on the machine:") -Fore Green
For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
    $Update = $SearchResult.Updates.Item($X)
    Write-Host( ($X + 1).ToString() + "> " + $Update.Title)
}
 
If ($SearchResult.Updates.Count -eq 0) {
    Write-Host("There are no applicable updates.")
    Exit
}
 
#Write-Host("")
#Write-Host("Creating collection of updates to download:") -Fore Green
 
$UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
 
For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
    $Update = $SearchResult.Updates.Item($X)
    #Write-Host( ($X + 1).ToString() + "&gt; Adding: " + $Update.Title)
    $Null = $UpdatesToDownload.Add($Update)
}
 
Write-Host("")
Write-Host("Downloading Updates...")  -Fore Green
 
$Downloader = $UpdateSession.CreateUpdateDownloader()
$Downloader.Updates = $UpdatesToDownload
$Null = $Downloader.Download()
 
#Write-Host("")
#Write-Host("List of Downloaded Updates...") -Fore Green
 
$UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
 
For ($X = 0; $X -lt $SearchResult.Updates.Count; $X++){
    $Update = $SearchResult.Updates.Item($X)
    If ($Update.IsDownloaded) {
        #Write-Host( ($X + 1).ToString() + "&gt; " + $Update.Title)
        $Null = $UpdatesToInstall.Add($Update)        
    }
}

If($Install){
    Write-Host("")
    Write-Host("Installing Updates. This can take a while...") -Fore Green
 
       $Installer = $UpdateSession.CreateUpdateInstaller()
       $Installer.Updates = $UpdatesToInstall
 
       $InstallationResult = $Installer.Install()
 
    Write-Host("")
    Write-Host("List of Updates Installed with Results:") -Fore Green
 
    For ($X = 0; $X -lt $UpdatesToInstall.Count; $X++){
        Write-Host($UpdatesToInstall.Item($X).Title + ": " + $InstallationResult.GetUpdateResult($X).ResultCode)
    }
 
    Write-Host("")
    Write-Host("Installation Result: " + $InstallationResult.ResultCode)
    Write-Host("    Reboot Required: " + $InstallationResult.RebootRequired)
}

If ($InstallationResult.RebootRequired -eq $True -and $Reboot){
    Write-Host("")
    Write-Host("Rebooting...") -Fore Green
    Restart-Computer -Force
}