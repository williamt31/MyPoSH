<#
# Class Name: Get-Adapters
# Purpose: To easily and quickly obtain network adapter information
#
# Operation: Obtains all network adapter alias names using invoke-command
#                       
# Creation Date: 2022-05-18
#__________________________________________________________________________________________________________________
#
#                                        ***  UNCLASSIFIED  ***
#__________________________________________________________________________________________________________________
#
#                       U.S. Army Research, Development, and Engineering Command
#                    Aviation and Missle Research, Development, and Engineering Center
#                       Software Engineering Directorate, Redstone Arsenal, AL
#__________________________________________________________________________________________________________________
#
# Export-Control Act Warning: WARNING - This document contains technical data whose ecport is restricted by the Arms
# Export Control Act (Title 22, U.S.C., Sec 2751, et seq) or the Export Administration Act of 1979, as amended, Title
# 50, U.S.C, App. 2401 et seq. Violations of these export laws are subject to severe criminal penalties.
# Disseminate in accordance with provisions of DoD Directive 5230.25.
#__________________________________________________________________________________________________________________
#
# Author: William Thompson
#
# Revision History:
#
# Name              SCR#                Date              Reason
# William Thompson                      05/18/2022        Initial release
# William Thompson                      06/23/2022        Added logging
#
#
#>
# GLOBAL FUNCTIONS DO NOT REMOVE ####################################
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    If ([Int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

# GLOBAL VARIABLES ##################################################
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogPath = "C:\Temp"
$LogFile = $LogPath + [char]92 + "Update-PowerCLI.Log"
$lInfo = "INFO"
$lWarning = "WARNING"
$lError = "ERROR"

#$Comps = "MYSHOP-Win-GP1","MYSHOP-Win-GP2","MYSHOP-Win-GP3","MYSHOP-Win-GP4","MYSHOP-Win-GP5","MYSHOP-Win-GP6"  # Test Group
$RunDate = "$( Get-Date -Format "yyyyMMdd_HHmmss" )"
$GoodOutput = $RunDate + "_Adapter_List.csv"
Add-Content -Path $GoodOutput -Value "Hostname,IP,InterfaceAlias"

$iCount = 1
$GoodComps = 0
$BadComps = 0

If ( -Not ( Test-Path -Path $LogPath ) ) {
    New-Item -ItemType Directory -Path $LogPath -Force
    If ( $? -eq $false ) {
        Add-Content -Value "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' )`tERROR`tUnable to create Log Directory" -Path "C:\CREATE_LOG_DIR_FAILED.Log" -PassThru
        Break 
    }
}
<###
# Function: 	Write-Log
# Purpose: 		Write Log to log file
#          		
# Parameters:	LogType & LogMessage
# 
# Dependencies:	N/A
# 
# Returns:		Outputs to Log file and terminal
###>
Function Write-Log ( $LogType, $LogMessage ) {
	Add-Content -Value "$( Get-Date -Format 'MM/dd/yyyy hh:mm:ss tt' )`t$LogType`t$LogMessage" -Path $LogFile -PassThru
}


# GLOBAL FUNCTIONS DO NOT REMOVE ####################################
<###
# Function: 	Get-File
# Purpose: 		Opens Windows File Dialog to select input file
#          		
# Parameters:	N/A
# 
# Dependencies:	Function Write-Log
# 
# Returns:		Outputs to Log file and terminal
###>
Function Get-File ( $GetWhat ) {
    Add-Type -AssemblyName System.Windows.Forms
    $GetFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Title = "Select input for $GetWhat"
        InitialDirectory = "C:\Scripts\myshopmgnt"
        Filter = 'CSV (*.csv)|*.csv|Text (*.txt;*.text)|*.txt;*.text|All (*.*)|*.*'
    }
    $null = $GetFile.ShowDialog()
    $FileExt = $GetFile.FileName.Split('.').Length -1
    $sExt = $GetFile.FileName.Split('.')[$FileExt]
    If ( $sExt -eq "txt" -or $sExt -eq "text" ) {
        $Results = Get-Content -Path ( $GetFile ).FileName
        Return $Results,$sExt
    }
    Elseif ( $sExt -eq "csv" ) {
        $Results = Import-Csv -Path ( $GetFile ).FileName | Select-Object -Property *
        Return $Results, $sExt
    }
    Write-Log $lInfo "Imported file: $GetFile"
}

# Begin Processing ##################################################
$GetCompList = Get-File "Computer List"
If ( $GetCompList[1] -eq "csv" ) {
    $Comps = $GetCompList[0].Hostname | Sort-Object -Unique
}
Else {
    $Comps = $GetCompList[0] | Sort-Object -Unique
}

foreach ( $i in $Comps ) {
    $tCount = $Comps.Count
    Write-Progress -Activity "Contacting Computer $i" -Status "Processing $iCount of $tCount    Completed: $GoodComps   Unable to Connect to: $BadComps" -PercentComplete $( $iCount/$tCount*100 )
    If ( Test-WSMan -ComputerName $i -ErrorAction 0 ) {
        $j = Invoke-Command -ComputerName $i -ScriptBlock {
            Get-NetIPAddress -AddressFamily "IPv4" -InterfaceIndex ( ( Get-NetAdapter |
            Where-Object { $_.Name -notlike "vEthernet*" }).ifIndex ) -EA 0
        }
        $GoodComps++
        If ( $j.Count ) {
            $z = $j.Count
            $z--
            While ( $z -gt -1 ) {
                $i = $j.PSComputerName[$z]
                $n = $j.IPAddress[$z]
                $o = $j.InterfaceAlias[$z]
                If ( $null -ne $j.IPAddress  ) {
                    Write-Log "lInfo Successfully gathered DNS Servers from $i`t$n`t$o"
                    Add-Content -Path $GoodOutput -Value "$i,$n,$o" -PassThru
                }
                $z--
            }
        }
        Else {
            $i = $j.PSComputerName
            $n = $j.IPAddress
            $o = $j.InterfaceAlias
            If ( $null -ne $j.IPAddress  ) {
                Write-Log "lInfo Successfully gathered DNS Servers from $i`t$n`t$o"
                Add-Content -Path $GoodOutput -Value "$i,$n,$o" -PassThru
            }
        }
    }
    else {
        $BadOutput = $RunDate + "_UnableToConnect.csv"
        Add-Content -Path $BadOutput -Value $i
        Write-Log $lError "Unable to Connect to: $i"
        $BadComps++
    }
    $iCount++
}

#______________________________________________________________________________________________________________________
#
#                                        ***  UNCLASSIFIED  ***
#______________________________________________________________________________________________________________________
