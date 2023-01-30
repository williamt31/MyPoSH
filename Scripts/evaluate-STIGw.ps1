# requires -Version 5
<###################################################################################################
# Org Banner Here!
####################################################################################################
.SYNOPSIS
    Wrapper script to make using NAVSEA script 'Evaluate-STIG' easier to use.
    
.DESCRIPTION
    Wrapper script that formats the arguments and simplifies input/output to 'Evaluate-STIG' script.
    
.INPUTS
    (Optional) List of Computer names.    
    
.OUTPUTS
    Copies scan results of NAVSEA script 'Evaluate-STIG' to location specified.
    
.EXAMPLE
    evaluate-STIGw.ps1

.NOTES
    Author:     Williamt31
    
    Version:    1.1
    Created:    20220808
    Updated:    20230130

.LINK
    https://spork.navsea.navy.mil/nswc-crane-division/evaluate-stig

.LINK

.COMPONENT
    Uses Evaluate-STIG from NAVSEA

###################################################################################################>
#----------------------------------------[Initialisations]-----------------------------------------#
# Self-elevate the script if required
If ( -Not ( [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] 'Administrator' ) ) {
    If ( [Int]( Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber ) -ge 6000 ) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}
#----------------------------------------[Declarations]--------------------------------------------#
# Set Error Action Preference
$ErrorActionPreference = "SilentlyContinue"
$ScriptName = ( [IO.FileInfo]$MyInvocation.MyCommand.Definition ).BaseName
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogPath = $ScriptPath
$LogFile = $LogPath + [char]92 + $ScriptName + ".Log"
$DateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"UTC")
$lInfo = "INFO"
$lWarning = "WARNING"
$lError = "ERROR"
$sVerbose = $false
$iCount = 1
$Done = $false
$Loops = 0
$StopWatch = New-Object -TypeName System.Diagnostics.StopWatch
$ReportDate = Get-Date -Format 'yyyyMM'
$ScriptLoc = < Network location 'Evaluate-STIG' files >
$ReportLoc = < Network location to upload scan results ie.  loc\$ReportDate >
#$$sArgs = "-ScanType UnClassified", "-ApplyTattoo", "-OutputPath $ReportLoc", "-ExcludeSTIG SQL2016DB, SQL2016Instance", "-ComputerName $($Comps -Join ",")" # Original line.
#$sArgs = "-ScanType UnClassified", "-ApplyTattoo", "-OutputPath $ReportLoc", "-ComputerName $($Comps -Join ",")", "-ExcludeSTIG SQL2016DB, SQL2016Instance" # If you need to run all BUT select scans, use this line.
$sArgs = "-ScanType UnClassified", "-ApplyTattoo", "-OutputPath $ReportLoc", "-ComputerName $($Comps -Join ",")", "-SelectSTIG Firefox" # If you only need to run a select scan use this line.
#----------------------------------------[Global Functions]----------------------------------------#
Function Write-Log ( $LogType, $sExitCode, $LogMessage ) {
<############################################################
# Function:     Write-Log
# Purpose:      Send Logs to screen and log file
#
# Parameters:   A Date-Time stamp will be generated each time the function is called
#               $LogType    Pass $lInfo, $lWarning or $lError
#               $sExitCode  Capture an Exitcode or create one to return
#               $LogMessage Custom message for each called instance
#
# Dependencies: None
#
# Returns:      Outputs to terminal and log file
############################################################>
    Add-Content -Value "$( Get-Date -Format 'yyyy/MM/dd hh:mm:ss tt' )`t$LogType`t$sExitCode`t$LogMessage"
}
Function Get-File ( $GetWhat ) {
<############################################################
# Function:     Get-File
# Purpose:      Open Windows File Open dialog box
#
# Parameters:   $GetWhat    Passing variable for named list
#
# Dependencies: None
#
# Returns:      Returns contents of file to function caller
############################################################>
    Add-Type -AssemblyName System.Windows.Forms
    $GetFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Title = "Select input for $GetWhat"
        InitialDirectory = "C:\"
        Filter = 'TXT (*.txt)|*.txt'
    }
    $null = $GetFile.ShowDialog()
    $Results = Get-Content -Path ( $GetFile ).FileName
    Return $Results
}
#----------------------------------------[Main Execution]------------------------------------------#
If ( $sVerbose ) { Write-Log $lInfo 0 "Begin executing $ScriptName" }
Write-Host "`nDo you want to scan a (S)ingle PC or (M)ultiple PCs?"
Write-Host -NoNewLine "(S/M/X): "
$Response = Read-Host
If ( $Response -eq "S" ) {
    Write-Host "`nEnter Hostname: "
    $Comps = Read-Host
}
ElseIf ( $Response -eq "M" ) {
    $Comps = Get-File "Computer List"
}
ElseIf ( $Response -eq "X" ) {
    Write-Host "`nExiting script`n"
    Pause
    Break
}
Else {
    Write-Host "`n`tUndefined answer, exiting script.`n"
    Pause
    Exit
}

Write-Log $lInfo "Sending Comps: $Comps to scanner."
Invoke-Expression "& `"$ScriptLoc`" $sArgs"
Pause
If ( $sVerbose ) { Write-Log $lInfo 0 "End executing $ScriptName" }
