# PowerShell One Liners

## Sectional stuff here

\# Get Start up Application info, User context and Location info via CIM
<br>Get-CimInstance Win32_StartupCommand | Select-Object Name,User,Description,Location,Command
<br>[Version]$OSVer = ((cmd /c ver).split()[4]).trim("]")

\# Get Network Adapter 'Ethernet' Link speed
<br>( Get-NetAdapterAdvancedProperty -Name Ethernet -DisplayName "Speed & Duplex" ).DisplayValue

\# Get Valid link speeds for Adatper 'Ethernet'
<br>( Get-NetAdapterAdvancedProperty -Name Ethernet -DisplayName "Speed & Duplex" ).ValidDisplayValues

\# Change link speed for Adapter 'Ethernet'
<br>( Set-NetAdatperAdvancedProperty -Name Ethernet -DisplayName "Speed & Duplex" -DisplayValue "Auto Negotiation"
