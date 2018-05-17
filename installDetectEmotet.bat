REM Install Chocolatey and upgrade it
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

choco upgrade chocolatey

REM Install Git for Windows and reload environment
choco install git -y

mkdir c:\ctms\git_repos
cd c:\ctms\git_repos

"C:\Program Files\Git\cmd\git.exe" clone https://github.com/CTMS/DetectEmotet.git

cd DetectEmotet\resources

@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -File installPS40.ps1

@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "shutdown -r -t ([decimal]::round(((Get-Date).AddDays(1).Date.AddHours(3) - (Get-Date)).TotalSeconds))"

schtasks /create /tn “Update DetectEmotet” /tr “C:\ctms\git_repos\DetectEmotet\resources\updateDetectEmotet.bat” /sc Weekly /d SAT /st 12:00 /ru “System”
