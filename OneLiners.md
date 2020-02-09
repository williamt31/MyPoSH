# PowerShell One Liners

## Sectional stuff here

\# Get Start up Application info, User context and Location info via CIM
<br>Get-CimInstance Win32_StartupCommand | Select-Object Name,User,Description,Location,Command
