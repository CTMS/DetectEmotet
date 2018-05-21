$cred = $Host.ui.PromptForCredential("Emotet Tasks Credentials", "Please enter credentials for Emotet Robot account.","$env:USERDNSDOMAIN\emotetbot","")

# Scheduled Task to run Detection script
#   Runs Countinous script
#   Ignores new instances if task still running
#   Attempts to start task daily at noon
#   Runs as emotetbot robot account with highest run level
$sta1 = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\ctms\git_repos\DetectEmotet\src\detect_emotet-continous.ps1"
$stt1 = New-ScheduledTaskTrigger -Daily -At 12:00
$sts1 = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName "Detect Emotet" -Force -Action $sta1 -Trigger $stt1 -Settings $sts1 -User $cred.username -Password $cred.getNetworkCredential().Password -RunLevel Highest

# Scheduled Task to run Update script
#   Runs Emotet Update script
#   Ignores new instances if task still running
#   Attempts to start task Every Sat at noon
#   Runs as emotetbot robot account with highest run level
$sta2 = New-ScheduledTaskAction -Execute "C:\ctms\git_repos\DetectEmotet\resources\updateDetectEmotet.bat"
$stt2 = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday -At 12:00
$sts2 = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName "Update Detect Emotet" -Force -Action $sta2 -Trigger $stt2 -Settings $sts2 -User $cred.username -Password $cred.getNetworkCredential().Password -RunLevel Highest
