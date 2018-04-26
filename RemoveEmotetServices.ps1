$regex = '^[0-9]+$'

#'AMPC171','CHEVPC33'

# Build out the array of effect PCs from the scanned list just put them one line at a time and then regex search (.*) and replace with '\1',
#$infectedPCs = ('AMPC171','CHEVPC33','GREENPC43','CHEVPC59','CHEVPC57','CHEVPC116','CHEVPC4','CHEVPC26','CHEVPC52','CHEVPC53','CHEVPC45','CHEVPC101','CHEVPC27','CHEVPC106','CHEVPC166','CHEVPC170')
$infectedPCs = ('AMPC171')

echo $infectedPCs

foreach ($i in $infectedPCs) {

   $client = $i
   Write-Host ("Testing Connection: {0}" -f $client)
   if (Test-Connection -Computername $client -BufferSize 16 -Count 1 -Quiet) {
      Write-Host("Getting services: {0}" -f $client)
      $services = get-service -ComputerName $client | Select-Object -expand name | Select-String -Pattern $regex
      foreach ( $service in $services ) 
      {
        Write-Host("Getting WMI service {0} on {1}" -f $service, $client)
        $serviceFull = Get-Service -ComputerName $client -Name $service.Name        
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