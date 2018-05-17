cd C:\ctms\DetectEmotet

. .\Get-RegistryKeyLastWriteTime.ps1

$regex = '^[0-9]+$'


$infectedPCs = Get-Content -Path PCList.txt

Write-Host $infectedPCs

foreach ($client in $infectedPCs) {
   Write-Host ("Testing Connection: {0}" -f $client)
   if (Test-Connection -Computername $client -BufferSize 16 -Count 1 -Quiet) {
      Write-Host("Getting services: {0}" -f $client)
      $services = get-service -ComputerName $client | Select-Object -expand name | Select-String -Pattern $regex

      $regKeyTimeStamps = @()

      foreach ( $service in $services )
      {
        Write-Host("Getting service {0} on {1}" -f $service, $client)
        $remoteregserv = Get-Service -ComputerName $client -Name RemoteRegistry
        $remoteregserv | Set-Service -StartupType Manual
        $remoteregserv | Start-Service

        $serviceFull = Get-Service -ComputerName $client -Name $service.Name
        $subKey = "SYSTEM\CurrentControlSet\Services\$service"

        Write-Host("Querying $subKey from $client")

        $regKeyTimeStamp = Get-RegistryKeyTimestamp -Computername $client -RegistryHive LocalMachine -SubKey $subKey

        $regKeyTimeStamps += $regKeyTimeStamp

        Get-Service -ComputerName $client -Name RemoteRegistry | Stop-Service

      }

      $regKeyTimeStamps | Sort-Object LastWriteTime -Descending
   }
   else {
    Write-Host  ("Computer {0} appears to be offline or inactive." -f $client)
}

}