# Function to Determine PC/Server/Domain Controller Configuration of PC

<br>Function Get-PCType(){
<br>`t	If ((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 1){
<br>`t`t		Write-Host "This is a Workstation"
<br>`t`t`t			}ElseIf((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2){
<br>`t`t				Write-Host "This is a Domain Controller"
<br>`t`t`t			}ElseIf((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 3){
<br>`t`t				Write-Host "This is a Server (But NOT a DC)"
<br>`t`t			}Else{Write-Host "Unknown PC Type"}}
