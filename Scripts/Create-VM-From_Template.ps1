#requires -Version 5
<######################################################################################################################
.SYNOPSIS
    Creates 1 or more VMs from a Template file.
  
.DESCRIPTION
    This cmdlet will create a blank VMs_Template.csv if one does not exist in current directory.
    On the next run it will load VM's from this template to create VMs on a VMWare vCenter cluster.
  
.NOTES
    Author:         williamt31
    https://github.com/williamt31
    
    Creation Date:  20220713
    Version:        Purpose/Change
    --------        --------------
    1.0             Intial Creation/Modification of Script

.INPUTS
    VMs_Template.csv
  
.OUTPUTS
    Creates VMs on the vCenter cluster coded in script.
  
.EXAMPLE
    Create-VM-From_Template.ps1

.NOTES
        

######################################################################################################################>
#------------------------------------------------[Initialisations]----------------------------------------------------#
<### Self-elevate the script If required ###>
If ( -Not ( [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] 'Administrator' ) ) {
	If ( [int]( Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber ) -ge 6000 ) {
		$CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
		Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
		Exit
	}
}

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"
#------------------------------------------------[Declarations]-------------------------------------------------------#
$sScriptVersion = "1.0"

$ScriptName = ( [IO.FileInfo]$MyInvocation.MyCommand.Definition ).BaseName
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sLogPath = $ScriptPath
$sLogFile = $sLogPath + [char]92 + $ScriptName + ".log"
$InputFile = "VMs_Template.csv"
$lInfo = "INFO"
$lWarning = "WARNING"
$lError = "ERROR"
$sVerbose = $false

$VsphereAdmin = "Administrator@vsphere.local"
$VIServer = "10.10.10.1"
$iCount = 1
$StopWatch  = New-Object -TypeName System.Diagnostics.Stopwatch

Set-PowerCliConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false > $null
Set-PowerCliConfiguration -Scope Session -ParticipateInCeip $false -Confirm:$false > $null
#------------------------------------------------[Global Functions]---------------------------------------------------#
# Default Functions
Function Write-Log ( $sLogType, $sExitCode, $sLogMessage ) {
<##########################################################
# Function: 	Write-Log
# Purpose: 	    Send Logs to screen and log file
#          		
# Parameters:	$sLogType
#               $sExitCode
#               $sLogMessage
# 
# Dependencies:	None
# 
# Returns:	    Outputs to terminal and log file
#
##########################################################>
    Add-Content -Value "$( Get-Date -Format 'yyyyMMdd hh:mm:ss tt' )`t$sLogType`t$sExitCode`t$sLogMessage" -Path $sLogFile -PassThru
}
#------------------------------------------------[User Functions]-----------------------------------------------------#
Function Test-InputFile () {
<##########################################################
# Function: 	Test-InputFile
# Purpose: 	    Test for existence of and data in $InputFile
#          		
# Parameters:	None
#               
# Dependencies:	None
# 
# Returns:      None  
#
##########################################################>
    If ( -Not ( Test-Path -Path $ScriptPath\$InputFile ) ) {
        Write-Log $lError 1 "Missing InputFile, creating empty template file: VMs_Template.csv"
        Add-Content -Path "$ScriptPath\$InputFile" -Value '"Name","Datastore","Template","VMHost","CPUs","RAM","VLAN"'
        If ( $? ) {
            Write-Log $lInfo 0 "Empty template created, please populate and re-launch script."
            Invoke-Item -Path "$ScriptPath\$InputFile"
        }
        Else {
            Write-Log $lError 1 "Unable to create: $ScriptPath\$InputFile"
        }
        Pause
        Break
    }
    If ( -Not ( Get-Content -Path $ScriptPath\$InputFile ).Count -gt 1 ) {
        Write-Log $lWarning 0 "No VMs in $InputFile to create, exiting."
        Pause
        Break
    }
}
#------------------------------------------------[Execution]----------------------------------------------------------#
Test-InputFile

If ( $sVerbose ) { Write-Log $lInfo 0 "Executing $ScriptName Version: $sVersion" }

If ( -Not ( $Global:DefaultVIServers ) ) {
    $VICreds = Get-Credential -UserName $VsphereAdmin -Message "Enter vCenter Administrator password"
    Connect-VIServer -Server $VIServer -Credential $VICreds
    If ( $Global:DefaultVIServers -ge 1 ) {
        Write-Log $lInfo 0 "Connected to vCenter"
    }
    Else {
        Write-Log $lError 1 "Unable to connect to vCenter, exiting"
        Pause
        Break
    }
}

$VMs = Import-CSV -Path "$ScriptPath\$InputFile"
If ( $sVerbose ) { Write-Log $lInfo 0 "Imported VMs from $InputFile" }

Write-Log $lInfo 0 "This will create the following:"
Write-Host "Name:`t`tDatastore:`tTemplate:`t`tVMHost:`t`tCPUs:`tRAM:`tVLAN:"
ForEach ( $VM in $VMs ) {
    Write-Host $( $VM.Name )`t$( $VM.Datastore )`t$( $VM.Template )`t$( $VM.VMHost )`t$( $VM.CPUs )`t$( $VM.RAM )`t$( $VM.VLAN )
}
Write-Host -NoNewLine "Continue (Y/N)"
$Response = Read-Host
If ( $Response -eq "N" ) {
    Write-Log 1 $lInfo "User Declined to continue, exiting script"
    Pause
    Break
}

ForEach ( $VM in $VMs ) {
    If ( -Not ( $VMs.Count ) ) {
        $tCount = 1
    }
    Else {
        $tCount = $VMs.Count
    }
    If ( $sVerbose ) { Write-Log $lInfo 0 "iCount: $iCount / tCount: $tCount" }
    $StopWatch.Start()
    Write-Progress -Activity "Creating VM: $( $VM.Name ) in Datastore: $( $VM.Datastore )" -Status "Processing $iCount of $tCount" -PercentComplete $( $iCount/$tCount*100 )
    New-VM -Name $VM.Name -Datastore $VM.Datastore -Template $VM.Template -VMHost $VM.Host > $null
    #New-VM -Name $VM.Name -Datastore $VM.Datastore -Template $VM.Template -VMHost $VM.Host -RunAsync > $null # Use this line to create all VMs simultaneously.
    Get-VM -Name $VM.Name | Set-VM -NumCPU $VM.CPUs -MemoryGB $VM.RAM -Confirm:$false > $null
    Set-NetworkAdapter -NetworkAdapter ( Get-NetworkAdapter -VM $VM.Name ) -NetworkName $VM.VLAN -Confirm:$false > $null
    $StopWatch.Stop()
    Write-Log $lInfo 0 "Created VM: $( $VM.Name ) in: $( $StopWatch.Elapsed.Minutes ):$( $StopWatch.Elapsed.Seconds )"
    $StopWatch.Reset()
    $iCount++
}
Pause
If ( $sVerbose ) { Write-Log $lInfo 0 "End executing $ScriptName Version: $sVersion" }
