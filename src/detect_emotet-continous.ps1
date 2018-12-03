[cmdletbinding()]
Param()

Import-module activedirectory

# Stateful Array for continual monitoring
# Clears the stateful table after import
$array = @()

mkdir C:\Logs
New-Item -path C:\Logs -name Emotet.log -type "file" -value "INFO Created Log File.`n" -Force
if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
    New-Item -path C:\Logs -name VerboseEmotet.log -type "file" -value "INFO Created Log File.`n" -Force
}
if (Test-Path "C:\Logs\data.csv") {
    $array += Import-CSV "C:\Logs\data.csv"
    clear-content "c:\Logs\data.csv"
}


# Global Variables
$log = "C:\Logs\Emotet.log"
$verboselog = "C:\Logs\VerboseEmotet.log"
$PCList = "C:\ctms\git_repos\DetectEmotet\src\PCList.txt"
$regex = '^[0-9]+$'
$computernames = Get-ADcomputer -Filter {(OperatingSystem -Notlike "*Server*") -and (Enabled -eq $True)} | Select-Object -Expand Name
$strDomainDNS = $env:USERDNSDOMAIN

if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
    $VerboseFlag = $true
}

# Writes to Log File
# INFO: Logs each time a cycle finishes
# ERROR: Logs each time a connection fails to a PC
# WARN: Logs positive matches already exist in stateful table for that day
# FATAL: Logs positive matches which are not in stateful table
#
# Use the following in powershell to tail the logfile:
#   Get-Content C:\Logs\Emotet.log -tail 10 -wait
Function Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [ValidateSet("INFO", "WARN", "ERROR", "FATAL", "DEBUG")]
        [String]
        $Level = "INFO",

        [Parameter(Mandatory = $True)]
        [string]
        $Message,

        [Parameter(Mandatory = $False)]
        [string]
        $logfile
    )

    $Stamp = (Get-Date).toString("yyyyMMdd HH:mm:ss")
    $Line = "$Stamp $Level $Message"

    # Tests for logfile and creates file if it does not exist
    Add-Content $logfile -Value $Line
}

function VerboseLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Message,
        [Parameter(Mandatory = $true)]
        [string]
        $logfile
    )

    if ($VerboseFlag) {
        Write-Log -Level "DEBUG" -Message $Message -logfile $logfile
    }
}

# Email Alerting Function
function EmailAlert {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]
        $To = "alerts@ctmsohio.com",

        [Parameter(Mandatory = $false)]
        [string]
        $Subject = "!!! Found New Emotet Indicator !!!",

        [Parameter(Mandatory = $true)]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [string]
        $SMTPServer = "mail.ctmsohio.com"
    )

    $SMTPPort = "25"
    $CC = "mjimerson@ctmsohio.com", "ecooper@ctmsohio.com", "jcriss@ctmsohio.com"
    $From = "Emotet_Alert@$strDomainDNS"

	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    Send-MailMessage -From $From -to $To -Subject $Subject `
        -Body $Message -SmtpServer $SMTPServer -Port $SMTPPort `
        -Cc $CC -UseSSL
}

# Main Function
while ($true) {
    foreach ($client in $computernames) {

        # Testing Connection to Client
        Write-Verbose ("Testing Connection: {0}" -f $client)
        if (Test-Connection -Computername $client -BufferSize 16 -Count 1 -Quiet) {
            Write-Verbose  "Connection established. Querying Remote Services..."
            VerboseLog -Message "Checking Services on $client." -logfile $verboselog
            try {
                $services = get-service -ComputerName $client | Select-Object -expand name | Select-String -Pattern $regex
            }
            catch {
                VerboseLog -Message "Service connection failed - " -logfile $verboselog
                VerboseLog -Message $_ -logfile $verboselog
                continue
            }
            # If indicator services are detected
            if ($services) {
                Write-Verbose  "!!!Found Emotet Indicators!!!"
                VerboseLog -Message "$client Services Found:`r`n $services" -logfile $verboselog
                $ipv4 = [System.Net.Dns]::GetHostAddresses($client) | ForEach-Object {$_.IPAddressToString } |Select-String -Pattern '\d+\.\d+\.\d+\.\d+'
                $date = (Get-Date).toString("yyyyMMdd")

                # Object before injection into stateful table
                $obj = New-Object psobject
                $obj | Add-Member -MemberType NoteProperty -Name "Hostname" -Value $client
                $obj | Add-Member -MemberType NoteProperty -Name "IPv4" -Value $ipv4
                $obj | Add-Member -MemberType NoteProperty -Name "Date" -Value $date

                # Parses stateful table to find if obj matches an item in table within 24 hour time frame
                # If match then it logs as a potential duplicate detection
                # Else it logs as a new infection
                $unique = 1
                foreach ($item in $array) {
                    if ($item.Hostname -eq $obj.Hostname -and $item.Date -eq $obj.Date) {
                        $unique = 0
                        VerboseLog -Message "Detection is not unique on $client -" -logfile $verboselog
                    }
                }
                if ($unique) {
                    $array += $obj
                    Write-Log -Level "FATAL" -Message "!!!Found Emotet Indicators!!!    $client : <$ipv4>" -logfile $log
                    VerboseLog -Message "Unique detection on $client - Sending Email" -logfile $verboselog
                    $smtpMessage = "!!!Found Emotet Indicators!!!    $client : <$ipv4>"
                    EmailAlert -Message $smtpMessage
                    if (!(Test-Path $PCList)) {
                        New-Item -Name $PCList -Type "file"
                    }
                    Add-Content $PCList -Value "$client"
                    $array | Select-Object Hostname, IPv4, Date | export-csv -LiteralPath "C:\Logs\data.csv"
                }
                else {
                    VerboseLog -Message "Duplicate detection on $client -" -logfile $verboselog
                    Write-Log -Level "WARN" -Message "Potential Duplicate Detection:    $client : <$ipv4>" -logfile $log
                }

                # DEBUG: Verbosity output to list services
                VerboseLog -Message "Found the following services:" -logfile $verboselog
                if ($VerboseFlag) {
                    foreach ($serv in $services) {
                        VerboseLog -Message "$client - Service Name: $serv" -logfile $verboselog
                    }
                }
            }
            else {
                VerboseLog -Message "Nothing found on $client :)" -logfile $verboselog
                Write-Verbose  "No Suspicous Services Found :)"
                continue
            }
        }
        else {
            # Logs connection failure to the client
            Write-Verbose  ("Computer {0} appears to be offline or inactive." -f $client)
            VerboseLog -Message "Failed to Connect to:    $client Offline" -logfile $verboselog
        }
    }
    VerboseLog -Message "Current Cycle Finished." -logfile $verboselog
    Write-Log -Level "INFO" -Message "Current Cycle Finished." -logfile $log
    # Writes stateful table to disk in csv format
    $array | Select-Object Hostname, IPv4, Date | export-csv -LiteralPath "C:\Logs\data.csv"
}
