<#
installPS40.ps1
Originally by: Evan Morrissey
Modified by: Tyler Jones
4.0 Modification by: Stephen Testino
Last Updated: 2014-08-11

Tests the version of PowerShell and attempts to update it to PowerShell 4.0
#>

param(
    [switch]$Reboot
)


# Declare the function for retrieving the update file
function HTTP-Download{
    param(
    $url
    ,
    $fileName
    )
    $webClient = New-Object System.Net.WebClient
    $localPath = "$env:temp\$fileName"
    $remote = $url + $fileName
    $ErrorActionPreference = "Stop"

    $path_check = Test-Path $localPath
    if($path_check -eq $False){
        try
        {
        $webClient.downloadFile($remote,$localPath)
        return $localPath
        }
        catch [System.Management.Automation.MethodInvocationException]
        {
        "Error downloading file" | Write-Host
        "Download URL: " + $url | Write-Host
        "Full Error message: " | Write-Host
        $error[0] | fl * -f | Write-Host
        return $false
        }
    }
    else{
    Write-Host "Download already exists. Try running"
    return $localPath
    }
}


# Find OS architecture
$psVer = $host.version
$os = get-wmiobject win32_operatingsystem
$osArch = "x64"

if ($os.osarchitecture -match "32")
{
    $osArch = "x86"
}

# Write date and existing PS details for logs
$date = get-date
"PowerShell 4.0 Install/Upgrade: " + $date | Write-Host
"`r`nInstalled PowerShell version: " + $psVer.toString() | Write-Host


# Check if powershell is already version 3 or higher
if ($psVer.major -gt 2)
{
    "`r`nPowerShell is already up to date, exiting" | Write-Host
    exit 0
}


# Check for versions of Windows not compatible with PowerShell 3.0
if (($os.version -lt 6.0) -or ($os.caption -match "vista") -or ($os.version -ge 6.2))
{
    "`r`nPowerShell 4.0 requires Windows 6.1 or greater, and is not compatible with Windows Vista. It is preloaded on Windows 8. No update required/possible. Exiting." | Write-Host
    exit 0
}
else{
    if($os.ServicePackMajorVersion -lt 1){
        "`r`nPowershell 4.0 requires SP1 atleast."
        exit 0
    }
}



# Download the installer
"`r`nAttempting to download latest PowerShell installer from Microsoft..."

# Create the download URL based on the windows version/architecture
$baseURL = "http://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/"
if ($os.version.subString(0,3) -eq 6.1)
{
    $psFile = "Windows" + $os.version.subString(0,3) + "-KB2819745-" + $osArch + "-MultiPkg" + ".msu"
}
else
{
    "Powershell 4.0 is not applicable to your PC"
}

if ($psFile -eq $null)
{
    "`r`nCould not generate a URL for download. Check Windows version to see if PowerShell 4.0 is compatible or required."
    exit 0
}

# Download function call
$dlResult = HTTP-Download $baseURL $psFile

if ($dlResult -eq $false)
{
    "`r`nDownload failed, please update PowerShell manually. Aborting script"
    exit 1
}
else
{
    # Install Windows Mangement Framework 4.0 (PowerShell 4.0)
    & $dlResult /quiet /norestart
    $i = 0
    Start-Sleep -Seconds 5
    while (get-process | ? {$_.processName -eq "wusa"})
    {
    start-sleep -seconds 10
    $i++
    if ($i -gt 300)
    {
        "`r`nPowerShell has been trying to install for 30 minutes?!? Aborting!"
        get-process | ? {$_.processName -eq "wusa"} | stop-process -force
        exit 1
    }
    }
    "`r`nPowerShell 4.0 Install complete: " + (get-date)

    if($Reboot){
    "`r`nInstall complete. Scheduling Reboot For 0300"
    Start-Sleep -Seconds 10
    shutdown -r -t ([decimal]::round(((Get-Date).AddDays(1).Date.AddHours(3) - (Get-Date)).TotalSeconds))
    }
}

