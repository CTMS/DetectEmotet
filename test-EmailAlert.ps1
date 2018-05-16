[cmdletbinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]
    $emailFrom,
    [Parameter(Mandatory = $true)]
    [string]
    $emailServer
)

function EmailAlert {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]
        $From,

        [Parameter(Mandatory = $false)]
        [string]
        $To = "alerts@ctmsohio.com",

        [Parameter(Mandatory = $false)]
        [string]
        $Subject = "Emotet Alerting Test Email",

        [Parameter(Mandatory = $true)]
        [string]
        $Message,

        [Parameter(Mandatory = $true)]
        [string]
        $SMTPServer
    )

    $SMTPPort = "25"
    $CC = "mjimerson@ctmsohio.com", "ecooper@ctmsohio.com", "jcriss@ctmsohio.com"

    Send-MailMessage -From $From -to $To -Subject $Subject `
        -Body $Message -SmtpServer $SMTPServer -Port $SMTPPort `
        -Cc $CC
}

$client = "test"
$ipv4 = "1.1.1.1"
$smtpMessage = "Emotet Alerting Test Email    $client : <$ipv4>"

EmailAlert -Message $smtpMessage -From $emailFrom -SMTPServer $emailServer
