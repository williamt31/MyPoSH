# requires -Version 5
<######################################################################################################################
.SYNOPSIS
    Facilitates connecting to Dev or Prod VmWare ENV.
  
.DESCRIPTION
    This cmdlet will facilitate connecting to VmWare servers.
  
.NOTES
    Author:         williamt31
    Creation Date:  20221018
    Version:        Purpose/Change
    --------        --------------
    1.0             Intial Creation/Modification of Script
  
.INPUTS
    N/A
  
.OUTPUTS
    N/A
  
.EXAMPLE
    Connect-ToVmWare.ps1

.NOTES
  
######################################################################################################################>
#------------------------------------------------[Initialisations]-----------------------------------------------------
# Self-elevate the script If required
If ( -Not ( [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] 'Administrator' ) ) {
	If ( [int]( Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber ) -ge 6000 ) {
		$CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
		Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
		Exit
	}
}

#------------------------------------------------[Declarations]--------------------------------------------------------
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ScriptName = ( [IO.FileInfo]$MyInvocation.Definition ).BaseName

# Log File Info
$LogPath = $ENV:Temp
$LogFile = $LogPath + [char]92 + $ScriptName + ".log"
$LogDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( [DateTime]::Now,"UTC" )
$lInfo = "INFO"
$lWarning = "WARNING"
$lError = "ERROR"
$sVerbose = $false

# Script Version
$ScriptVersion = "1.0"

# Script Specific
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction -Ignore -Confirm:$false > $null
Set-PowerCLIConfiguration -Scope User -ParticipateInCeip $false -Confirm:$false > $null
$DevVcenter		= ""
$DevESXi		= ""
$ProdVcenter	= ""
$ProdESXi		= ""
#------------------------------------------------[Global Functions]---------------------------------------------------
<###
# Function:	Write-Log
# Purpose:	Write Log to log file
#
# Parameters:	LogType, sExitCode & LogMessage
#
# Dependencies: N/A
#
# Returns:	Outputs to Log file and terminal
###>
Function Write-Log ( $sLogType, $sExitCode, $sLogMessage ) {
    Add-Content -Value "$( Get-Date -Format 'yyyyMMdd hh:mm:ss tt' )`t$sLogType`t$sExitCode`t$sLogMessage" -Path $LogFile -PassThru
}

If ( -Not ( ( $Global:DefaultVIServers ).Count -eq 0 ) ) {
	$Global:DefaultVIServers | Disconnect-ViServer -Confirm:$false > $null
	If ( $sVerbose ) { Write-Log $lInfo 0 "Disconnecting from $Global:ViServers"
}
#---------------------------------------------------------[User Functions]----------------------------------------------------------
Function Set-Server () {
	Write-Host "`n`tDo you want to connect to the (D)ev or (P)rod VmWare ENV?"
	Write-Host -NoNewLine "`tNOTE: At any time you can type 'X' to Exit: "
	$Response = Read-Host
	If ( $Response -eq "D" ) {
		Write-Host "`tUser chose Dev"
		Write-Host -NoNewLine "`tDo you want to connect to v(C)enter or a (E)SXi host?: "
		$Response = Read-Host
		If ( $Response -eq "C" ) {
			Write-Host "`tUser chose vCenter"
			$VIServer = 
			$VAdmin = 


}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log $lInfo 0 "Beginning script: $ScriptName, Version: $sScriptVersion, Path: $ScriptPath"
#Script Execution goes here







Write-Log $lInfo 0 "Finised script: $ScriptName, Version: $sScriptVersion, Path: $ScriptPath"
