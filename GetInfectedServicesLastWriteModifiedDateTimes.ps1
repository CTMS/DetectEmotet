cd C:\ctms\DetectEmotet

. .\Get-RegistryKeyLastWriteTime.ps1

$regex = '^[0-9]+$'

#
#$infectedPCs = ('AMPC171','CHEVPC33','GREENPC43','CHEVPC59','CHEVPC57','CHEVPC116','CHEVPC4','CHEVPC26','CHEVPC52','CHEVPC53','CHEVPC45','CHEVPC101','CHEVPC27','CHEVPC106','CHEVPC166','CHEVPC170')
$infectedPCs = ('CHEVPC186')

echo $infectedPCs

foreach ($i in $infectedPCs) {

   $client = $i
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

        echo "Querying $subKey from $client"

        $regKeyTimeStamp = Get-RegistryKeyTimestamp -Computername $client -RegistryHive LocalMachine -SubKey $subKey

        $regKeyTimeStamps += $regKeyTimeStamp

        Get-Service -ComputerName $client -Name RemoteRegistry | Stop-Service

      }

      $regKeyTimeStamps | sort LastWriteTime -Descending
   }
   else {
    Write-Host  ("Computer {0} appears to be offline or inactive." -f $client)
}

}