#requires -Version 5
<######################################################################################################################
#
.SYNOPSIS
    

.DESCRIPTION
    

.NOTES
    Author:         William Thompson


    Creation Date:  20220718
    Version:        Purpose/Change:
    --------        ---------------
    1.0             Initial Creation

.INPUTS
    

.OUTPUTS
    

.EXAMPLE
    Invoke-NetworkSettings -Capture
    Invoke-NetworkSettings -Deploy    

.NOTES


######################################################################################################################>
Param
    (
    [ Parameter( Mandatory = $false ) ][Switch] $Capture,
    [ Parameter( Mandatory = $false ) ][Switch] $Deploy
    #[ Parameter( Mandatory = $false ) ][String] $ComputerName = $ENV:ComputerName
    )
#------------------------------------------------[Initialisations]----------------------------------------------------#
<### Self Elevate script if needed. ###>
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    If ([Int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
#------------------------------------------------[Declarations]-------------------------------------------------------#
$sVersion = 1

$ScriptName = ( [IO.FileInfo]$MyInvocation.MyCommand.Definition ).BaseName
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogPath = $ScriptPath
$LogFile = $LogPath + [char]92 + $ScriptName + ".Log"
$DateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"UTC")
#$OutputFile = "NetworkSettings_" + $( Get-Date -Format "yyyyMMdd" ) + ".csv"
$OutputFile = "NetworkSettings_" + $( $DateTime ).ToString( 'yyyyMMdd' ) + ".csv"
$lInfo = "INFO"
$lWarning = "WARNING"
$lError = "ERROR"
$sVerbose = $false
$iCount = 1
$Done = $false
$Loops = 0
$StopWatch = New-Object -TypeName System.Diagnostics.StopWatch

#------------------------------------------------[Global Functions]---------------------------------------------------#
Function Write-Log ( $LogType, $sExitCode, $LogMessage ) {
<##########################################################
# Function: 	Write-Log
# Purpose: 		Sends Logs to screen and log file
#          		
# Parameters:	$sLogType
#               $sExitCode
#               $sLogMessage
# 
# Dependencies:	None
# 
# Returns:		Outputs to terminal and log file
##########################################################>
	Add-Content -Value "$( Get-Date -Format 'yyyy/MM/dd hh:mm:ss tt' )`t$LogType`t$sExitCode`t$LogMessage" -Path $LogFile -PassThru
}
#------------------------------------------------[User Functions]-----------------------------------------------------#
Function Capture-NetworkInfo () {
<##########################################################
# Function: 	Capture-NetworkInfo
# Purpose: 		Captures specific network properties
#          		
# Parameters:	None
# 
# Dependencies:	Write-Log
# 
# Returns:		Outputs to log file
##########################################################>
If ( $sVerbose ) { Write-Log $lInfo 0 "Capturing Network Adapter info for $ComputerName" }
    Foreach ( $i in ( ( Get-NetIPAddress -AddressFamily "IPv4" ).InterfaceAlias -NotLike "*Loopback*" ) )  {
        $A = Get-NetIPAddress -InterfaceAlias $i -AddressFamily "IPv4"
        $B = Get-NetIPConfiguration -InterfaceAlias $i
        $C = Get-DnsClientServerAddress -InterfaceAlias $i -AddressFamily "IPv4"
        $DateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"UTC")
        #$Date = Get-Date -Format "yyyyMMdd"
        #$Time = Get-Date -Format "HH:mm"
        [PSCustomObject]@{
            ComputerName            = $B.ComputerName
            InterfaceAlias          = $A.InterfaceAlias
            MacAddress              = $B.NetAdapter.MacAddress
            Status                  = $B.NetAdapter.Status
            InterfaceDescription    = $B.InterfaceDescription
            IP                      = $B.IPv4Address.IPAddress
            PrefixLength            = $A.PrefixLength
            Gateway                 = $B.IPv4DefaultGateway.NextHop
            DNS                     = ( @( $C.ServerAddresses ) -join ',' )
            Date                    = ( $DateTime ).ToString( 'yyyyMMdd' )
            Time                    = ( $DateTime ).ToString( 'HH:mm' )
        }
    }
}

#------------------------------------------------[Execution]----------------------------------------------------------#
If ( $sVerbose ) { Write-Log $lInfo 0 "Executing $ScriptName Version: $sVersion" }
# Tests if multiple flags were called
If ( $Capture -and $Deploy ) {
    Write-Host "`n`tYou can only select (D)eploy OR (C)apture, try again."
    $Capture = $false
    $Deploy = $false
}
# Tests if NO flags were called
If ( -Not ( $Capture -or $Deploy ) ) {
    Write-Host "`n`tPlease select (C)apture, (D)eploy or e(X)it."
    Write-Host -NoNewline "`t(C/D/X): "
    $Response = Read-Host
    If ( $Response -eq "C" ) {
        Write-Host "User chose to Capture"
        $Capture = $true
    }
    ElseIf ( $Response -eq "D" ) {
        Write-Host "User chose to Deploy"
        $Deploy = $true
    }
    ElseIf ( $Response -eq "X" ) {
        Write-Host "`tExiting script"
        Pause
        Break
    }
    Else {
        Write-Host "`tUndefined answer, exiting script."
        Pause
        Break
    }
}
# Obtains target list
Write-Host "`n`tAre you targetting a (S)ingle system, (M)ultiple systems or the (L)ocal System?"
Write-Host -NoNewLine "`t(S/M/L/X): "
$Response = Read-Host
If ( $Response -eq "L" ) {
    $ComputerList = @($ENV:ComputerName)
}
ElseIf ( $Response -eq "S" ) {
    Write-Host "`tEnter Computer Name: "
    $ComputerList  = @( Read-Host )
}
ElseIf ( $Response -eq "M" ) {
$ComputerList = get-computers.....

}


If ( $Capture ) {
    ForEach ( $Comp in $ComputerList ) {
        $tCount = $ComputerList.Count
        If ( $sVerbose ) { Write-Log $lInfo 0 "iCount: $iCount / tCount: $tCount" }
        Write-Progress -Activity "Connecting to $Comp" -Status "Processing $iCount of $tCount" -PercentComplete $( $iCount/$tCount*100 )
        If ( $Comp -eq $ENV:ComputerName ) {
            $Comp = "localhost"
        }
        If ( Test-WSMan -ComputerName $Comp -ErrorAction 0 ) {
            $Results = Invoke-Command `
                -ComputerName $Comp `
                -ScriptBlock ${Function:Capture-NetworkInfo} |
                Select-Object -Property `
                ComputerName, InterfaceAlias, MacAddress, Status, InterfaceDescription, IP, PrefixLength, Gateway, DNS, Date, Time
        }
        $iCount++
        While ( -Not $Done -and $loops -lt 100 ) {
            Try {
                $Results | Export-CSV -NoTypeInformation -Path $ScriptPath\$OutputFile -Append
                $Done = $true
            } 
            Catch {
                Write-Host $_.Exception
                Write-Host $_.ErrorDetails
                Write-Host $_.ScriptStackTrace
                Write-Host "Unable to write to file, please close it!"
                Start-Sleep -Seconds 5
                $loops += 1
            }
        }
    }
}







If ( $Deploy ) {
    Write-Host "Deploy flagged"


}







If ( $sVerbose ) { Write-Log $lInfo 0 "End executing $ScriptName Version: $sVersion" }
