# Misc. Functions

## Function to Determine PC/Server/Domain Controller Configuration of PC
<p>Function Get-PCType(){
<br>&emsp;If ((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 1){
<br>&emsp;&emsp;Write-Host "This is a Workstation"
<br>&emsp;&emsp;}ElseIf((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2){
<br>&emsp;&emsp;&emsp;Write-Host "This is a Domain Controller"
<br>&emsp;&emsp;}ElseIf((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 3){
<br>&emsp;&emsp;&emsp;Write-Host "This is a Server (But NOT a DC)"
<br>&emsp;&emsp;}Else{Write-Host "Unknown PC Type"}
<br>&emsp;}

