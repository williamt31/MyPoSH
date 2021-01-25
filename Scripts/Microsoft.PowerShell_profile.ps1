function Get-Excuse {
    (Invoke-WebRequest http://pages.cs.wisc.edu/~ballard/bofh/excuses -OutVariable excuses).content.split([Environment]::NewLine)[(get-random $excuses.content.split([Environment]::NewLine).count)]
}

$Console = $Host.UI.RawUI
$Console.ForeGroundColor = "Green"
$Console.BackGroundColor = "Black"
$MaximumHistoryCount = 250

$Window = $Console.WindowSize
$Window.Width = 150
$Window.Height = 50
$Console.WindowSize = $Window

$ScrollBack = $Console.BufferSize
$ScrollBack.Height = 3000
$ScrollBack.Width = 150
$Console.BufferSize = $ScrollBack

$user = [Security.Principal.WindowsIdentity]::GetCurrent()
	If ( (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
	$adminfg = "Red"
	} Else {
		$adminfg = $host.ui.rawui.ForegroundColor
	}

Function Prompt { Write-Host ("[" + $(Get-Date -Format "yyMMdd HH:mm") + "]") -NoNewLine -ForeGroundColor Cyan ; 
Write-Host " PS" -NoNewLine -ForeGroundColor $Adminfg ; 
Write-Host " ~$(Split-Path $PWD -Leaf): > "  -NoNewLine -ForeGroundColor Cyan ; 
Return " " }
#Clear-Host

# Custom TypeData
Update-TypeData "C:\Scripts\MyTypes.ps1xml"

# Drive Mounts
#If (Test-Path -Path "\\X.X.X.X\Movies") {
#	If (!(Test-Path -Path "Movies:")) {
#		New-PsDrive -Name "Movies" -PSProvider "FileSystem" -Root "\\X.X.X.X\Movies"
#	}}

# Aliases
# Set Preferred Editor Alias 'Nano' to 'Notepadd++' or 'Notepad'
If (Test-Path -Path "C:\Program Files (x86)\Notepad++\Notepad++.exe" -PathType Leaf) {
	Set-Alias Nano "C:\Program Files (x86)\Notepad++\Notepad++.exe"} ElseIf (
		Test-Path -Path "C:\Windows\System32\Notepad.exe") {
	Set-Alias Nano "C:\Windows\System32\Notepad.exe"
	}

# Functions			
# Function ll [Mode, LastWriteTime, FileSize(Human Readable), FileName]
Function ll(){
	param(
		[Parameter(Mandatory=$False)]$Location
		)
	If (!(Get-ChildItem -At !D)){
		Echo "No Files Found"
	}
	If (!($Location)){
		Get-ChildItem -At !D $PWD | Format-Table $ll_exps
	}
	Else{
		Get-ChildItem -At !D $Location | Format-Table $ll_exps
	}
}	

Function Grep(){
	param(
		[Parameter(Mandatory=$True)]$Term
		)
	Get-Content (Get-PSReadlineOption).HistorySavePath | Select-String -Pattern $Term
}	

Function Refresh-Env() { $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") }
Function Get-TTF (){Get-Childitem -Path ./ -At !D -Recurse | Sort-Object -Property Length -Descending | Select-Object FileSize,Length,Name -First 10 | Format-Table Name,FileSize}
Function CDS (){ Set-Location -Path "C:\Scripts" }

Refresh-Env
Set-Location "C:\Scripts"