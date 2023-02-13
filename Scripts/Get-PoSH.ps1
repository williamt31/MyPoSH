<#
.SYNOPSIS
    Downloads latest powershell.<latest ver>.tar.gz
    
.DESCRIPTION
    Script to get latest PoSH tar for Evaluate-STIG and rename it as needed.
    
.INPUTS
    N/A
    
.OUTPUTS
    Downloads latest powershell 7.x and renames it to -> powershell.tar.gz
    
.EXAMPLE
    Get-PoSH.ps1
.NOTES
    Author:     Williamt31
    
    Version:    1.0
    Created:    20230131

.LINK
    https://github.com/PowerShell/PowerShell/releases

.COMPONENT
    
#> # Do NOT modify the format above this line or it will break help functionality!
#Requires -Version 5.1
####################################################################################################
# !Org Banner Here!
####################################################################################################
#----------------------------------------[Declarations]--------------------------------------------#
$ScriptName = ( [IO.FileInfo]$MyInvocation.MyCommand.Definition ).BaseName
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogPath = $ScriptPath
$LogFile = $LogPath + [char]92 + $ScriptName + ".Log"
$lInfo = "INFO"
$PoSHfile = "powershell.tar.gz"
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
        #Add-Content -Value "$( Get-Date -Format 'yyyy/MM/dd hh:mm:ss tt' )`t$LogType`t$sExitCode`t$LogMessage" -Path $LogFile -PassThru
        $DateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"UTC").ToString('yyyy/MM/dd hh:mm:ss tt')
        Add-Content -Value "$DateTime`t$LogType`t$sExitCode`t$LogMessage" -Path $LogFile -PassThru
    }
#----------------------------------------[Main Execution]------------------------------------------#
# Code to get the file for the latest version of Powershell 7.x
$url = 'https://github.com/PowerShell/PowerShell/releases/latest'
$request = [System.Net.WebRequest]::Create($url)
$response = $request.GetResponse()
$realTagUrl = $response.ResponseUri.OriginalString
$newVer = $realTagUrl.split('/')[-1].Trim('v')
$versionFile = "Powershell_$newVer.txt"
$fileName = "powershell-$newVer-linux-x64.tar.gz"
$realDownloadUrl = $realTagUrl.Replace('tag', 'download') + '/' + $fileName
$response.close()
# If there is currently a "powershell_7.x.x.txt" file will compare the '7.x.x' in the file to the version online.
If ( Test-Path -Path "$ScriptPath\Powershell_*.txt" ) {
    $currentPoshFile = ( Get-ChildItem -Path "$ScriptPath\powershell.tar.gz" -ErrorAction SilentlyContinue ).Name 
    $currentVerFile = ( Get-ChildItem -Path "$ScriptPath\Powershell_*.txt" -ErrorAction SilentlyContinue ).BaseName
    $currentVer = ( ( $currentVerFile ).Split("_")[1] )
}
If ( $newVer -eq $currentVer ) {
    Write-Log $lInfo 0 "No update available"
    Return 1
}
# If there is a different version online vs local will delete the current powershell.tar.gz, the version file and download the latest, rename and recreate the version file.
Else {
    If ( $null -ne $currentPoshFile ) {
        Remove-Item -Path $ScriptPath\$PoSHfile
    }
    If ( $null -ne $currentVerFile ) {
        Remove-Item -Path "$ScriptPath\$currentVerFile.txt"
    }

    Invoke-WebRequest -Uri $realDownloadUrl -OutFile $ScriptPath\$PoSHfile
    If ( $? -eq $True ) {
        Write-Log $lInfo 0 "Successfully downloaded $fileName"
        Unblock-File -Path $ScriptPath\$PoSHfile
        New-Item -Path $ScriptPath -Name $versionFile -ItemType "File"
    }
    Return 0
}
