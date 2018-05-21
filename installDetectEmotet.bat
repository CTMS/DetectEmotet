@ECHO OFF
set /p REBOOT=Schedule Reboot for 0300 for Powershell upgrade? (y)es / (n)o:

echo Installing Chocolatey and upgrade it
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

choco upgrade chocolatey

echo Install Git for Windows and reload environment
choco install git -y

echo Creating git directory and downloading repo
mkdir c:\ctms\git_repos
cd c:\ctms\git_repos
"C:\Program Files\Git\cmd\git.exe" clone https://github.com/CTMS/DetectEmotet.git

cd DetectEmotet\resources

echo Attempting to Upgrade Powershell to version 4
IF "%REBOOT%"=="y" GOTO withReboot
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -File installPS40.ps1
GOTO Next
:withReboot
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -File installPS40.ps1 -Reboot
:Next

echo Setting up Scheduled Tasks
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -File createSchTasks.ps1

echo Testing Email Alerting Feature
cd c:\ctms\git_repos\DetectEmotet\src
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -File test-EmailAlert.ps1

echo Done
timeout /t 15