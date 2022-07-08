#requires -version 5
<####################################################################################################
.SYNOPSIS
  <Overview of script>
  
.DESCRIPTION
  <Brief description of script>
  
.NOTES
  Author:         williamt31
  Creation Date:  20220707
  Version:        Purpose/Change
  --------        --------------
  1.0             Intial Creation/Modification of Script

.INPUTS
  <Inputs if any, otherwise state None>
  
.OUTPUTS
  <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
  
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
  
####################################################################################################>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
# Self-elevate the script If required
If ( -Not ( [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] 'Administrator' ) ) {
	If ( [int]( Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber ) -ge 6000 ) {
		$CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
		Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
		Exit
	}
}

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Script Version
$sScriptVersion = "1.0"

# Log File Info
$sLogPath = "C:\Logs"
$sLogName = ([IO.FileInfo]$MyInvocation.MyCommand.Definition).BaseName
$sLogDate = Get-Date -Format "yyyy-MM-dd_HH-mm_"
$sLogFile = $sLogPath + [char]92 + $sLogDate + $sLogName + ".log"
$ScriptPath= Split-Path -Parent $MyInvocation.MyCommand.Definition
$ScriptName = $MyInvocation.MyCommand.Name

#-------------------------------------------------------[Default Functions]----------------------------------------------------------
# Default Functions
If ( -Not ( Test-Path -Path $sLogPath ) ) {
	New-Item -ItemType Directory -Path $sLogPath -Force | Out-Null
	If ( $? -eq $False ) {
		Add-Content -Value "$( Get-Date -Format 'yyyyMMdd hh:mm:ss tt' )`tERROR`tUnable to create Log Directory" -Path "C:\CREATE_LOG_DIR_FAILED.Log" -PassThru
		exit
	}
}

Function Write-Log ( $sLogType, $sExitCode, $sLogMessage ) {
    Add-Content -Value "$( Get-Date -Format 'yyyyMMdd hh:mm:ss tt' )`t$sLogType`t$sExitCode`t$sLogMessage" -Path $sLogFile -PassThru
}

#---------------------------------------------------------[User Functions]----------------------------------------------------------



#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-Log $lInfo 0 "Beginning script: $ScriptName, Version: $sScriptVersion, Path: $ScriptPath"
#Script Execution goes here







Write-Log $lInfo 0 "Finised script: $ScriptName, Version: $sScriptVersion, Path: $ScriptPath"
