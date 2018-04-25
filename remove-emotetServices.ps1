$computers = Get-Content -Path "C:\CTMS\PCList.txt"
foreach ($client in $computers) {
    $services = get-service -ComputerName $client | Select-Object -expand name | Select-String -Pattern $regex

    foreach ($serv in $services) {
        Write-Host ("Service Name: {0}" -f $serv)
        Write-Host ("Deleting Service...")
        icm -ComputerName $client -ScriptBlock {Remove-Item -Path "hklm:\SYSTEM\CurrentControlSet\Services\$serv" -Confirm:$false}
    }
}