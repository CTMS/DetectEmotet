# DetectEmotet
Script framework to detect service signatures for Emotet banking trojan on Active Directory PCs.

**_Requires Powershell V4 or higher_**


## **Installation**
Run the following command from an elevated command prompt. Make sure you have an active internet connection. The script will ask you if you want to reboot the server at 0300 to finish installing Powershell V4.
> @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -enc KABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQARgBpAGwAZQAoACcAaAB0AHQAcABzADoALwAvAHIAYQB3AC4AZwBpAHQAaAB1AGIAdQBzAGUAcgBjAG8AbgB0AGUAbgB0AC4AYwBvAG0ALwBDAFQATQBTAC8ARABlAHQAZQBjAHQARQBtAG8AdABlAHQALwBtAGEAcwB0AGUAcgAvAGkAbgBzAHQAYQBsAGwARABlAHQAZQBjAHQARQBtAG8AdABlAHQALgBiAGEAdAAnACwAJwBDADoAXABXAGkAbgBkAG8AdwBzAFwAVABlAG0AcABcAGkAbgBzAHQAYQBsAGwARABlAHQAZQBjAHQARQBtAG8AdABlAHQALgBiAGEAdAAnACkAOwAgAEMAOgBcAFcAaQBuAGQAbwB3AHMAXABUAGUAbQBwAFwAaQBuAHMAdABhAGwAbABEAGUAdABlAGMAdABFAG0AbwB0AGUAdAAuAGIAYQB0AA==

This will run the installation script which installs chocolatey, git, Powershell 4, and Detect Emotet. It then sets up the scheduled tasks to update Detect Emotet on a Weekly basis and the task to run the continous detection script. Finally, it will test the email alerting function.


### **detect_emotet-once.ps1**
This will run through all online AD computers and query services for numerical regex patterns. Will then log the PC name and IP then send an alert email to CTMS. It then adds the PC name to a text file in the working directory to use with other scripts.


### **detect_emotet-continous.ps1**
This will do the same thing as the single run but continually on a loop. It will also maintain a stateful database table to determine if the detection is new or already been discovered.


### **GetInfectedServicesLastWriteModifiedDateTimes.ps1**
This will read the PCList.txt file which is a list of infected PC names. It will query the services and find the last date/time that the service registry keys were modified and print it to the console.


### **RemoveEmotetServices.ps1**
This will read from the PCList.txt file and then remove all the signature services from the computers in that list. **_Only use this after infection has been cleared!_**


### **test-EmailAlert**
This will allow you to test the email alert functions for the script before deployment.

