#requires -Version 5
<######################################################################################################################
#
.SYNOPSIS
    Facilitates connecting to Dev or Prod VmWare ENV.

.DESCRIPTION
    This cmdlet will facilitate connecting to VmWare servers.

.NOTES
    Author:         William Thompson

    Creation Date:  20221018
    Version:        Purpose/Change:
    --------        ---------------
    1.0             Initial Creation

.INPUTS
    N/A

.OUTPUTS
    N/A

.EXAMPLE
    Connect-ToVmWare.ps1

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

If ( -Not ( ( $Global:DefaultVIServers ).Count -eq 0 ) ) {
    $Global:DefaultVIServers | Disconnect-ViServer -Confirm:$false > $null
    If ( $sVerbose ) { Write-Log $lInfo 0 "Disconnecting from $Global:VIServers" }
}

#------------------------------------------------[User Functions]-----------------------------------------------------#
Function Set-Server () {
    Write-Host "`n`tDo you want to connect to the (D)ev or (P)rod VmWare ENV?"
    Write-Host -NoNewline "`tNOTE: At any time you can type 'X' to Exit: "
    $Response = Read-Host
    If ( $Response -eq "D" ) {
        Write-Host "`tUser chose Dev"
        Write-Host -NoNewline "`tDo you want to connect to v(C)enter or a (E)SXi host?: "
        $Response = Read-Host
        If ( $Response -eq "C" ) {
            Write-Host "`tUser chose vCenter"
            $VIServer = ""
            $VAdmin = "administrator@vsphere.local"
        }
        ElseIf ( $Response -eq "E" ) {
            Write-Host "`tUser chose ESXi host"
            $VIServer = ""
            $VAdmin = "root"
        }
    }
    ElseIf ( $Response -eq "P" ) {
        Write-Host "`tUser chose to Prod"
        Write-Host -NoNewline "`tDo you want to connect to v(C)enter or a (E)SXi host?: "
        $Response = Read-Host
        If ( $Response -eq "C" ) {
            Write-Host "`tUser chose vCenter"
            $VIServer = ""
        }
        ElseIf ( $Response -eq "E" ) {
            Write-Host "`tUser chose connect to ESXi host"
            Write-Host -NoNewline "`tWhich Production ESXi host .8(1), .8(2) or .8(3)?: "
            $Response = Read-Host
            If ( $Response -eq "1" ) {
                Write-Host "`tUser chose .81"
                $VIServer = ""
            }
            ElseIf ( $Response -eq "2" ) {
                Write-Host "`tUser chose .82"
                $VIServer = ""
            }
            ElseIf ( $Response -eq "3" ) {
                Write-Host "`tUser chose .83"
                $VIServer = ""            
            }
            Else {
                Write-Host "`tUndefined answer, exiting script."
                Pause
                Break
            }
            $VAdmin = "root"
        }
    }
    ElseIf ( $Response -eq "X" ) {
        Write-Host "`tUser chose to Exit"
        Break
    }
    Else {
        Write-Host "`tUndefined answer, exiting script."
        Pause
        Break
    }
    Return $VAdmin, $VIServer
}
#------------------------------------------------[Execution]----------------------------------------------------------#
Try {
    If ( $sVerbose ) { Write-Log $lInfo 0 "Executing $ScriptName Version: $sVersion" }
    $VAdmin, $VIServer = Set-Server
    $VCreds = Get-Credential -Username $VAdmin -Message "Enter password (Correct Username if needed)"
    Connect-ViServer -Server $VIServer -Credential $VCreds > $null
    If ( $? ) {
        Write-Log $lInfo 0 "Connected to $VIServer"
    }
    Else {
        Write-Log $lError 99 "Failed to Connect to $VIServer"
    }
}

Catch {
    Write-Log $lError 99 "Caught Error: $ExitCode"
}

Finally {
    Write-Host "Script Executed successfully!"
    If ( $sVerbose ) { Write-Log $lInfo 0 "End executing $ScriptName Version: $sVersion" }
}
