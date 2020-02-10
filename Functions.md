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

## Function to Determin Zone Identifier of Downloaded File
<p>Function Get-ZoneIdent($1){
<br>&emsp;If ((Get-Item $1 -Stream Zone.Identifier) -eq 0){
<br>&emsp;&emsp;Write-Host "$1 Came from Zone 'My Computer'"
<br>&emsp;}ElseIf((Get-Item $1 -Stream Zone.Identifier) -eq 1){
<br>&emsp;&emsp;Write-Host "$1 came from Zone 'Local Intranet Zone'"
<br>&emsp;}ElseIf((Get-Item $1 -Stream Zone.Identifier) -eq 2){
<br>&emsp;&emsp;Write-Host "$1 came from Zone 'Trusted Sites Zone'"
<br>&emsp;}ElseIf((Get-Item $1 -Stream Zone.Identifier) -eq 3){
<br>&emsp;&emsp;Write-Host "$1 came from Zone 'Internet Zone'" 
<br>&emsp;}ElseIf((Get-Item $1 -Stream Zone.Identifier) -eq 4){
<br>&emsp;&emsp;Write-Host "$1 came from Zone 'Restricted Sites Zone'" 
<br>&emsp;}Else{Write-Host "Unknown Zone Info"}
<br>&emsp;}
