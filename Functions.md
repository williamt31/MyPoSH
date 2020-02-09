# Misc. Functions

## Function to Determine PC/Server/Domain Controller Configuration of PC

<p> Function Get-PCType(){
    If ((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 1){
&emsp;&emsp;&emsp;      Write-Host "This is a Workstation"
     }ElseIf((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2){
      Write-Host "This is a Domain Controller"
    }ElseIf((Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 3){
      Write-Host "This is a Server (But NOT a DC)"
    }Else{Write-Host "Unknown PC Type"}}

