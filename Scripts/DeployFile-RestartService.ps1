# Script created to replace a file on all networked PC's and restart a service.

# Self-elevate the script if required
If ( -Not ( [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] 'Administrator' ) ) {
	If ( [int]( Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber ) -ge 6000 ) {
		$CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
		Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
		Exit
	}
}
# Begin Variable Declaration
$Domain=( [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name )
$FileToCopy = "\\<Insert network location here>\inputs.conf"
$RemoteDest = "Program Files\Splunkuniversalforwarder\etc\apps\splunkuniversalforwarder\local"
$OUBase = "OU=Computers,DC=Domain,DC=com"
$Computers = Get-AdComputer -filter * -searchbase $OUBase | Select-Object -ExpandProperty Name

Foreach ( $Comp in $Computers ) {
    Try { Copy-Item $FileToCopy "\\$Comp\C$\$RemoteDest\" -Force }
    Catch [System.IO.IOException]{}
}

Start-Sleep 15

Invoke-Command -ComputerName $Computers -ScriptBlock {
    Restart-Service -Name "SplunkForwarder"
} -AsJob -ErrorAction SilentlyContinue
