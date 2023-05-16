#requires -Version 5
<######################################################################################################################
#
.SYNOPSIS
    Eases STIG settings so ESXi servers don't end/drop sessions while troubleshooting issues.

.DESCRIPTION
    This cmdlet will facilitate Troubleshooting VmWare ESXi servers.

.NOTES
    Author:         williamt31

    Creation Date:  20221110
    Version:        Purpose/Change:
    --------        ---------------
    1.0             Initial Creation

.INPUTS
    N/A

.OUTPUTS
    N/A

.EXAMPLE
    Troubleshoot-ESXi.ps1

.NOTES

######################################################################################################################>
#------------------------------------------------[Initialisations]----------------------------------------------------#
If ( -Not ( [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    If ( [Int]( Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber ) -ge 6000 ) {
        $CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

#------------------------------------------------[Declarations]-------------------------------------------------------#
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptName = ( $MyInvocation.MyCommand.Name ).Split(".")[0]
$LogFile = $ScriptPath + [char]92 + $ScriptName + ".log"
$LogDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( [DateTime]::Now,"UTC" )
$lInfo = "INFO"
$lWarning = "WARNING"
$lError = "ERROR"
$sVerbose = $false
$StopWatch = New-Object -TypeName System.Diagnostics.StopWatch
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false > $null
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -Confirm:$false > $null

#------------------------------------------------[Global Functions]---------------------------------------------------#
<###
# Function: 	Write-Log
# Purpose: 		Write Log to log file
#          		
# Parameters:	LogType, ExitCode & LogMessage
# 
# Dependencies:	N/A
# 
# Returns:		Outputs to Log file and terminal
###>
Function Write-Log ( $LogType, $sExitCode, $LogMessage ) {
	Add-Content -Value "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' )`t$LogType`t$sExitCode`t$LogMessage" -Path $LogFile -PassThru
}

#------------------------------------------------[User Functions]-----------------------------------------------------#
# Flags
$Enable  = "Lock"
$Disable = "UnLock"

Function Set-STIGSettings ( $Flag ) {
    If ( $Flag -eq "Lock" ) {
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} | Set-VMHostService -Policy Off -Confirm:$false > $null          # V-239290
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} | Stop-VMHostService -Confirm:$false                             # V-239290
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'ESXi Shell'} | Set-VMHostService -Policy Off -Confirm:$false > $null   # V-239291
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'ESXi Shell'} | Stop-VMHostService -Confirm:$false                      # V-239291
        Get-VMHost | Get-AdvancedSetting -Name UserVars.ESXiShellInteractiveTimeOut | Set-AdvancedSetting -Value 120 -Confirm:$false        # V-239296
        Get-VMHost | Get-AdvancedSetting -Name UserVars.ESXiShellTimeOut | Set-AdvancedSetting -Value 600 -Confirm:$false                   # V-239297
        Get-VMHost | Get-AdvancedSetting -Name UserVars.DcuiTimeOut | Set-AdvancedSetting -Value 120 -Confirm:$false                        # V-239298
    }
    ElseIf ( $Flag -eq "UnLock" ) {
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} | Set-VMHostService -Policy On -Confirm:$false > $null           # V-239290
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} | Start-VMHostService -Confirm:$false                            # V-239290
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'ESXi Shell'} | Set-VMHostService -Policy On -Confirm:$false > $null    # V-239291
        Get-VMHost | Get-VMHostService | Where-Object {$_.Label -eq 'ESXi Shell'} | Start-VMHostService -Confirm:$false                     # V-239291
        Get-VMHost | Get-AdvancedSetting -Name UserVars.ESXiShellInteractiveTimeOut | Set-AdvancedSetting -Value 0 -Confirm:$false          # V-239296
        Get-VMHost | Get-AdvancedSetting -Name UserVars.ESXiShellTimeOut | Set-AdvancedSetting -Value 0 -Confirm:$false                     # V-239297
        Get-VMHost | Get-AdvancedSetting -Name UserVars.DcuiTimeOut | Set-AdvancedSetting -Value 0 -Confirm:$false                          # V-239298
    }
}

#------------------------------------------------[Execution]----------------------------------------------------------#
If ( $sVerbose ) { Write-Log $lInfo 0 "Begin executing $ScriptName Version: $sVersion" }

If ( ( $Global:DefaultVIServers ).Count -eq 1 ) {
    If ( ( $Global:DefaultVIServers.Name.Split(".")[3] -eq 81 ) -or
        ( $Global:DefaultVIServers.Name.Split(".")[3] -eq 82 ) -or
        ( $Global:DefaultVIServers.Name.Split(".")[3] -eq 83 ) ) {
        Write-Log $lInfo 0 "Connected to and using ESXi host: $Global:DefaultVIServers"
    }
    ElseIf ( $Global:DefaultVIServers.Name.Split(".")[3] -eq 80 ) {
        Write-Log $lWarning 1 "You are connected to vCenter, please disconnect and connect to a single ESXi host."
        Exit
    }
Else {
    Write-Log $lError 2 "You are NOT connected to any ESXi hosts, check connection."
    Exit
}
}

Write-Host -NoNewline "`nDo you want to proceed? (y/n): "
$Response = Read-Host
If ( $Response -ne "Y" ) {
    Write-Log $lInfo "User chose NOT to continue, Exiting script!"
    Exit
}

Write-Host "The purpose of this script is to unset/set various STIG settings to aid in troubleshooting."
Write-Host "It will enable or disable things like DCUI console access, SSH, and adjust timeout settings."
Write-Host -NoNewline "`nSelect (U)nlock, (L)ock or E(x)it to quit. "
$Response = Read-Host
If ( $Response -eq "U" ) {
    Write-Log $lInfo "Removing STIG settings"
    Set-STIGSettings $Disable
}
Elseif ( $Response -eq "L" ) {
    Write-Log $lInfo "Setting STIG settings back!"
    Set-STIGSettings $Enable
}
Elseif ( $Response -eq "X" ) {
    Write-Log $lInfo "User chose to Exit!"
    Exit
}

If ( $sVerbose ) { Write-Log $lInfo 0 "End executing $ScriptName Version: $sVersion" }
