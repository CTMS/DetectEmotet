[cmdletbinding()]
Param()

$strDomainDNS = $env:USERDNSDOMAIN

function EmailAlert {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]
        $To = "alerts@ctmsohio.com",

        [Parameter(Mandatory = $false)]
        [string]
        $Subject = "Emotet Alerting Test Email",

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

    Send-MailMessage -From $From -to $To -Subject $Subject `
        -Body $Message -SmtpServer $SMTPServer -Port $SMTPPort `
        -Cc $CC
}

$client = "test"
$ipv4 = "1.1.1.1"
$smtpMessage = "Emotet Alerting Test Email    $client : <$ipv4>"

EmailAlert -Message $smtpMessage
