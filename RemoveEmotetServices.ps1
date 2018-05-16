$regex = '^[0-9]+$'

#'AMPC171','CHEVPC33'

$infectedPCs = Get-Content -Path PCList.txt

Write-Host $infectedPCs

foreach ($client in $infectedPCs) {
    Write-Host ("Testing Connection: {0}" -f $client)
    if (Test-Connection -Computername $client -BufferSize 16 -Count 1 -Quiet) {
        Write-Host("Getting services: {0}" -f $client)
        $services = get-service -ComputerName $client | Select-Object -expand name | Select-String -Pattern $regex
        foreach ( $service in $services ) {
            Write-Host("Getting WMI service {0} on {1}" -f $service, $client)
            $wmiFilter = "Name='$service'"
            Write-Host("wmiFilter: $wmiFilter")
            $wmiService = Get-WmiObject -ComputerName $client -Class Win32_Service -Filter $wmiFilter
            Write-Host ($wmiService)
            $wmiService.delete();
            Get-Service -ComputerName $client -Name RemoteRegistry | Stop-Service
        }
    }
    else {
        Write-Host  ("Computer {0} appears to be offline or inactive." -f $client)
    }

}

Clear-Content PCList.txt