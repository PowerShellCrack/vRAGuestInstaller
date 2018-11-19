
<#PSScriptInfo

.VERSION 1.0

.GUID bae78b34-2bd5-42ce-9577-ec348b598570

.AUTHOR Microsoft Corporation

.COMPANYNAME Microsoft Corporation

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

<#

.DESCRIPTION
 Test the compatibility of current system with WMF 5.1 and install the package if requirements are met.

#>

##Check OS Version is below Windows 10.
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string] $UpdatesPath,
    [switch] $AcceptEULA,
    [switch] $AllowRestart
)

$ErrorActionPreference = 'Stop'

function New-TerminatingErrorRecord
{
    param(
        [string] $exception,
        [string] $exceptionMessage,
        [system.management.automation.errorcategory] $errorCategory,
        [string] $targetObject
    )

    $e = New-Object $exception $exceptionMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $e, $errorId, $errorCategory, $targetObject
    return $errorRecord
}

function Test-Compatibility
{
    $returnValue = $true

    $BuildVersion = [System.Environment]::OSVersion.Version

    if($BuildVersion.Major -ge '10')
    {
        Write-Host 'WMF 5.1 is not supported for Windows 10 and above.' -ForegroundColor Red
        $returnValue = $false
    }

    ## OS is below Windows Vista
    if($BuildVersion.Major -lt '6')
    {
        Write-Host ("WMF 5.1 is not supported on BuildVersion: {0}" -f $BuildVersion.ToString()) -ForegroundColor Red
        $returnValue = $false
    }

    ## OS is Windows Vista
    if($BuildVersion.Major -eq '6' -and $BuildVersion.Minor -le '0')
    {
        Write-Host ("WMF 5.1 is not supported on BuildVersion: {0}" -f $BuildVersion.ToString()) -ForegroundColor Red
        $returnValue = $false
    }

    ## Check if WMF 3 is installed
    $wmf3 = Get-WmiObject -Query "select * from Win32_QuickFixEngineering where HotFixID = 'KB2506143'"

    if($wmf3)
    {
        Write-Host ("WMF 5.1 is not supported when WMF 3.0 is installed.") -ForegroundColor Red
        $returnValue = $false
    }

    # Check if .Net 4.5 or above is installed

    $release = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Release -ErrorAction SilentlyContinue -ErrorVariable evRelease).release
    $installed = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Install -ErrorAction SilentlyContinue -ErrorVariable evInstalled).install

    if($evRelease -or $evInstalled)
    {
        Write-Host ("WMF 5.1 requires .Net 4.5.") -ForegroundColor Red
        $returnValue = $false
    }
    elseif (($installed -ne 1) -or ($release -lt 378389))
    {
        Write-Host ("WMF 5.1 requires .Net 4.5.") -ForegroundColor Red
        $returnValue = $false
    }

    return $returnValue
}

if($PSBoundParameters.ContainsKey('AllowRestart') -and (-not $PSBoundParameters.ContainsKey('AcceptEULA')))
{
    $errorParameters = @{
                                    exception = 'System.Management.Automation.ParameterBindingException';
                                    exceptionMessage = "AcceptEULA must be specified when AllowRestart is used.";
                                    errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument;
                                    targetObject = ""
                        }

    $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
}

[psobject]$envOS = Get-WmiObject -Class 'Win32_OperatingSystem' -ErrorAction 'SilentlyContinue'
[string]$envOSName = $envOS.Caption.Trim()
[string]$envOSServicePack = $envOS.CSDVersion
[version]$envOSVersion = [Environment]::OSVersion.Version
[string]$envOSVersionMajor = $envOSVersion.Major
[string]$envOSVersionMinor = $envOSVersion.Minor
$OSVersionMajorMinor = "$envOSVersionMajor.$envOSVersionMinor"
#get OS Major minor version and assign msu name to it
Switch($OSVersionMajorMinor){
    "6.3" {$x86MSU = "Win8.1-KB3191564-x86.msu"
           $x64MSU = "Win8.1AndW2K12R2-KB3191564-x64.msu"
    }
    "6.2" {$x86MSU = "Win8.1-KB3191564-x86.msu"
           $x64MSU = "Win8.1AndW2K12R2-KB3191564-x64.msu"
    }
    "6.1" {$x86MSU = "Win7-KB3191566-x86.msu"
           $x64MSU = "Win7AndW2K8R2-KB3191566-x64.msu"
    }
    "6.0" {$x64MSU = "W2K12-KB3191565-x64.msu"
    }

}

#get ARCHITECTURE and assign package name to it from MSU
if($env:PROCESSOR_ARCHITECTURE -eq 'x86'){    
    $packageName = $x86MSU
}
else{
    $packageName = $x64MSU
}

$packagePath = Resolve-Path (Join-Path $UpdatesPath $packageName)
Write-Host "WMF 5.1 update found: $packagePath";
if($packagePath -and (Test-Path $packagePath))
{
        if(Test-Compatibility)
        {
            $wusaExe = "$env:windir\system32\wusa.exe"
            if($PSCmdlet.ShouldProcess($packagePath,"Install WMF 5.1 Package from:"))
            {
                $wusaParameters = @("`"{0}`"" -f $packagePath)

                ##We assume that AcceptEULA is also specified
                if($AllowRestart)
                {
                    $wusaParameters += @("/quiet /warnrestart:5")
                }
                ## Here AllowRestart is not specified but AcceptEULA is.
                elseif ($AcceptEULA)
                {
                    $wusaParameters += @("/quiet", "/promptrestart")
                }

                $wusaParameterString = $wusaParameters -join " "
                & $wusaExe $wusaParameterString

                #wait for process to end
                $wusaprocess = Get-Process -ProcessName ([IO.path]::GetFileNameWithoutExtension($wusaExe)) -ErrorAction SilentlyContinue
                $wusaprocess | Wait-Process
            }
        }
        else
        {
            $errorParameters = @{
                                    exception = 'System.InvalidOperationException';
                                    exceptionMessage = "WMF 5.1 cannot be installed as pre-requisites are not met. See Install and Configure WMF 5.1 documentation: https://go.microsoft.com/fwlink/?linkid=839022";
                                    errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                                    targetObject = $packagePath
                                }

            $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
        }
}
else
{
    $errorParameters = @{
                            exception = 'System.IO.FileNotFoundException';
                            exceptionMessage = "Expected WMF 5.1 Package: `"$packageName`" was not found.";
                            errorCategory = [System.Management.Automation.ErrorCategory]::ResourceUnavailable;
                            targetObject = $packagePath
                            }

    $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
}