#requires -version 5
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.NOTES
  Author:         williamt31
  Creation Date:  20210109
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
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

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

#-------------------------------------------------------[Default Functions]----------------------------------------------------------
# Default Functions
# MUST BE FIRST TO CHECK LOG FILE PATH
Function Log_Path_Test(){
    If(!(Test-Path $sLogPath)){
        New-Item -ItemType Directory -Force -Path $sLogPath -ErrorAction Stop  | Out-Null
    } ELSE {
        Write-Output "`n`tUnable to create Log Dir`n"
        Exit
    }
}

# MUST BE SECOND TO WRITE TO LOG FILE
Function sLogWrite($sExitStatus, $sExitCode, $sExitMsg){
    Add-Content -Path $sLogFile -Value "$sExitStatus`t$sExitCode`t$sExitMsg"
}

#---------------------------------------------------------[User Functions]----------------------------------------------------------
Function Log_Path_Test2(){
    If(!(Test-Path $sLogPath)){
        New-Item -ItemType Directory -Force -Path $sLogPath -ErrorAction Stop  | Out-Null
    } ELSE {
        Write-Output "Unable to create Log Dir"
    }
    sLogWrite "[SUCCESS]" "0" "Script Executed Successfully"
}



#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
#Log-Finish -LogPath $sLogFile

#Log_Path_Test
Log_Path_Test2