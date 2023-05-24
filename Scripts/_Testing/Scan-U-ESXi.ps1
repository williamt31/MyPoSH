#requires -version 5
<#
#
.SYNOPSIS
    Scan ESXi server for vulnerabilities using STIG V1R1 23Mar07

.DESCRIPTION
    Using Powershell, PowerCLI and local commands to check if settings are set

.NOTES
  Author:         williamt31
  Creation Date:  20230502
  Version:        Purpose/Change
  --------        --------------
  1.0             Intial Creation of Script

.INPUTS
    N/A

.OUTPUTS
    Outputs log to '<Date>_ScriptName.log'

.PARAMETER <Parameter_Name>
    N/A
  
.EXAMPLE
    ./Scan-ESXi.ps1

#>
#------------------------------------------------[Initialisations]----------------------------------------------------------
# U # The purpose of this code block is to auto elevate, it this is not needed comment it out.
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    If ([Int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}
#------------------------------------------------[Declarations]-------------------------------------------------------------
# Clear $Error stack
$Error.Clear()
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sScriptVersion = "1.0"
$sDataStore = "DATASTORE:\_iso-Tools\STIGstuff"
# Log File Info
$sLogPath = $ScriptPath
$sLogName = ([IO.FileInfo]$MyInvocation.MyCommand.Definition).BaseName
$sLogDate = Get-Date -Format "yyyyMMdd_"
$sLogFile = $sLogPath + [char]92 + $sLogDate + $sLogName + ".log"
$lInfo = "INFO"
$lWarning = "WARNING"
$lError = "ERROR"
# Arrays to catalog findings
$cIFind   = @{}
$cIIFind  = @{}
$cIIIFind = @{}
# Captures additional logging while testing.
$sVerbose = 0
$StopWatch = New-Object -TypeName System.Diagnostics.StopWatch
# Set Error Action to Silently Continue if needed.
$ErrorActionPreference = "SilentlyContinue"
#------------------------------------------------[Global Functions]---------------------------------------------------------
<###
# Function:     Write-Log
# Purpose:      Logging of steps
#          		
# Dependencies: N/A
# 
# Inputs:       Variable: $sLogType can be "$lInfo" "$lWarning" or "$lError"
#               Variable: $sLogMessage more detailed message
#
# Returns:		Outputs to Log file and terminal
###>
Function Write-Log ( $sLogType, $sLogMessage ) {
    Add-Content -Value "$( Get-Date -Format 'yyyyMMdd hh:mm:ss tt' )`t$sLogType`t$sLogMessage" -Path $sLogFile -PassThru
}
#------------------------------------------------[User Functions]-----------------------------------------------------------
<###
# Function:     Test-Connection
# Purpose:      Verify connection to a VMware server
#          		
# Dependencies: N/A
# 
# Inputs:       N/A
#
# Returns:		N/A, Exits script if not connected
###>
Function Test-Connection () {
    If ( -Not ( ( $Global:DefaultVIServers ).Count -gt 0 ) ) {
        Write-Log $lError "You are not currently connected to any VMware servers, check your connection and retry script."
        Exit 1
    }
}
<###
# Function:     Get-Hosts
# Purpose:      Gets connected VMware hosts
#          		
# Dependencies: Need to be connected to a VMware server
# 
# Inputs:       N/A
#
# Returns:		N/A
###>
Function Get-Hosts () {
    $Script:VmHosts = @( ( Get-VMHost ).Name )
    #Write-Host $lInfo "Connected to ESXi Hosts: $VmHosts"
}
<###
# Function:     Set-SSH
# Purpose:      Toggle on/off SSH connectivity
#          		
# Dependencies: Need to be connected to a VMware server
# 
# Inputs:       Variable: $Flag, can be either 'Open' or 'Close'
#
# Returns:		N/A
###>
Function Set-SSH ( $Flag ) {
    If ( $Flag -eq "Open" ) {
        Get-VMHost $h | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} | Set-VMHostService -Policy On -Confirm:$False > $null
        Get-VMHost $h | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} | Start-VMHostService -Confirm:$False > $null
        Get-VMHost $h | Get-AdvancedSetting -Name UserVars.ESXiShellInteractiveTimeOut | Set-AdvancedSetting -Value 0 -Confirm:$False > $null
    }
    ElseIf ( $Flag -eq "Close" ) {
        Get-VMHost $h | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} | Stop-VMHostService -Confirm:$False > $null
        Get-VMHost $h | Get-AdvancedSetting -Name UserVars.ESXiShellInteractiveTimeOut | Set-AdvancedSetting -Value 120 -Confirm:$False > $null
    }
}
<###
# Function:     Add-Vuln
# Purpose:      Add the VULN to its corresponding CAT array for reporting
#          		
# Dependencies: Need to be connected to a VMware server
# 
# Inputs:       Variable: $CAT, Severity category
#               Variable: $VULN, Vulnerability ID
#               Variable: $RuleTitle, Title of Rule
#
# Returns:		N/A
###>
Function Add-Vuln ( $CAT, $VULN, $RuleTitle ) {
    If ( $sVerbose -ge 2 ) {
        Write-Log $lInfo "$CAT, $VULN, $RuleTitle"
    }
    If ( $CAT -eq "I" ) {
        $cIFind.Add( $VULN, $RuleTitle )
    }
    ElseIf ( $CAT -eq "II" ) {
        $cIIFind.Add( $VULN, $RuleTitle )
    }
    ElseIf ( $CAT -eq "III" ) {
        $cIIIFind.Add( $VULN, $RuleTitle )
    }
    Else {
        Write-Log $lWarning "Unable to match variable CAT: $CAT for Vuln: $VULN"
    }
}
#------------------------------------------------[Echo Scan_ESXi.sh]--------------------------------------------------------
$Scan_ESXi = @'
# U #
####################################################################################################
#!/bin/sh
# Created by: williamt31
# Created on: 20230510
# Version: V1R1 2023Mar07
# Purpose: Check for VMware vSphere 7.0 STIG settings
####################################################################################################
# U # Global variables set here #
h=$( hostname -i )
HOST=$(hostname | awk -F "." '{print $1}')
DATE=$(date '+%Y%m%d')
LOGFILE="ESXiScan.log"
####################################################################################################
# U # Global functions set here #
####################################################################################################
# U # Begin processing #
####################################################################################################
echo -e "\n# U # Begin execution of :${0##*/} script!\n"
# Removing old log file if it exists
if [ -f $LOGFILE ]
then
    rm $LOGFILE
fi
touch $LOGFILE
# Removing old settings if existing in /etc/ssh/sshd_config
sed -i /^GSSAPIAuthentication/d /etc/ssh/sshd_config
sed -i /^KerberosAuthentication/d /etc/ssh/sshd_config
# Begin rule checks
RuleTitle="The ESXi host SSH daemon must be configured with the DOD logon banner."
VULN="V-256383"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep banner )
TRUTH="banner /etc/issue"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must ignore ".rhosts" files."
VULN="V-256385"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep ignorerhosts )
TRUTH="ignorerhosts yes"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must not allow host-based authentication."
VULN="V-256386"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep hostbasedauthentication )
TRUTH="hostbasedauthentication no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must not allow authentication using an empty password."
VULN="V-256387"
CAT="III"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep permitemptypasswords )
TRUTH="permitemptypasswords no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must not permit user environment settings."
VULN="V-256388"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep permituserenvironment )
TRUTH="permituserenvironment no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must perform strict mode checking of home directory configuration files."
VULN="V-256389"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep strictmodes )
TRUTH="strictmodes yes"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must not allow compression or must only allow compression after successful authentication."
VULN="V-256390"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep compression )
TRUTH="compression no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must be configured to not allow gateway ports."
VULN="V-256391"
CAT="III"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep gatewayports )
TRUTH="gatewayports no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must be configured to not allow X11 forwarding."
VULN="V-256392"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep x11forwarding )
TRUTH="x11forwarding no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must not permit tunnels."
VULN="V-256393"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep permittunnel )
TRUTH="permittunnel no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must set a timeout count on idle sessions."
VULN="V-256394"
CAT="III"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep clientalivecountmax )
TRUTH="clientalivecountmax 3"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must set a timeout interval on idle sessions."
VULN="V-256395"
CAT="III"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep clientaliveinterval )
TRUTH="clientaliveinterval 200"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host must enable Secure Boot."
VULN="V-256430"
CAT="II"
TEST=$( /usr/lib/vmware/secureboot/bin/secureBoot.py -s )
TRUTH="Enabled"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host Secure Shell (SSH) daemon must disable port forwarding."
VULN="V-256434"
CAT="II"
TEST=$( /usr/lib/vmware/openssh/bin/sshd -T | grep allowtcpforwarding )
TRUTH="allowtcpforwarding no"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host must not be configured to override virtual machine (VM) configurations."
VULN="V-256444"
CAT="II"
TEST=$( stat -c "%s" /etc/vmware/settings )
TRUTH="0"
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

RuleTitle="The ESXi host must not be configured to override virtual machine (VM) logger settings."
VULN="V-256445"
CAT="II"
TEST=$( grep "^vmx\.log" /etc/vmware/config )
TRUTH=""
if [ "$TEST" == "$TRUTH" ]
    then
    Finding="False"
elif [ "$TEST" != "$TRUTH" ]
    then
    Finding="True"
else
    Finding="Error"
fi
echo -e "$(date -u +%Y%m%e\ %r)\tINFO\t$h\t$CAT\t$VULN\t$Finding\t$TEST" | tee -a $LOGFILE

echo -e "\n# U # End of Script!\n"
'@ -replace "`r`n","`n"
$Scan_ESXi | Set-Content Scan_ESXi.sh
#------------------------------------------------[Execution]----------------------------------------------------------------
If ( $sVerbose -ge 1 ) {
    Write-Host "`n"
    Write-Log $lInfo "### Begin executing $sLogName Version: $sScriptVersion`n"
    $StopWatch.Start()
}
Test-Connection
New-PSDrive -PSProvider VimDatastore -Root '\' -Name NETAPP_LUN_1 -Location $( Get-Datastore -Name NETAPP_LUN_1 ) > $null
If ( -Not ( Test-Path $sDataStore ) ) {
    New-Item -Type Directory $sDataStore
    Write-Log $lWarning "Missing remote path, creating: $sDataStore"
}
Get-Hosts
ForEach ( $h in $VmHosts ) {
    Write-Host "`n`t###############################"
    Write-Host "`t# Working on host: $h #"
    Write-Host "`t###############################`n"

# Begin remote scanning section
If ( Test-Path $sDataStore ) {
    # Enable SSH connections to ESXi host.
    Set-SSH "Open"
    Copy-DatastoreItem -Item .\Scan_ESXi.sh -Destination $sDataStore
    Write-Warning -Message "Select to (S)uspend script now and manually SSH to $h`
     Navigate to the DataStore /vmfs/volumes/NETAPP_LUN_1/_iso-Tools/STIGstuff and copy 'Scan-ESXi.sh' to /tmp`
     Run: chmod +x /tmp/Scan_ESXi.sh
     The from the DataStore dir execute /tmp/Scan-ESXi.sh`
     When completed type exit twice and (y) to continue." -WarningAction Inquire
    Copy-DatastoreItem -Item $sDataStore\ESXiScan.log -Destination .
    # Disable SSH connections to ESXi host.
    Set-SSH "Close"
    Add-Content -Path $sLogFile -Value $( Get-Content -Path .\ESXiScan.log )
    Remove-Item .\ESXiScan.log
}

    $RuleTitle = "Access to the ESXi host must be limited by enabling lockdown mode."
    $VULN = "V-256375"
    $CAT = "II"
    $TEST = (Get-VMHost $h).Extensiondata.Config.LockdownMode
    If ( ( $TEST -eq "lockdownNormal" ) -Or ( $TEST -eq "lockdownStrict" ) ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "lockdownDisabled" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must verify the DCUI.Access list."
    # Notes: Script assumes Vcenter connected
    $VULN = "V-256376"
    $CAT = "II"
    $TEST = ( ( Get-VMHost $h | Get-AdvancedSetting -Name DCUI.Access ).Value )
    If ( $TEST -eq "root" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "root" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must verify the exception users list for lockdown mode."
    # Notes: (Empty) Value returned as an empty array.
    # Notes: Need to test how to verify non-finding set.
    $VULN = "V-256377"
    $CAT = "II"
    $TEST = ( ( Get-View ( ( Get-VMHost $h | Get-View ).ConfigManager.HostAccessManager ) ).QueryLockdownExceptions() )
    If ( $TEST.Length -ne 0 ) {
        $Finding = $False
    }
    Elseif ( $TEST.Length -eq 0 ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "Remote logging for ESXi hosts must be configured."
    $VULN = "V-256378"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Syslog.global.logHost ).Value
    If ( $TEST -ne "" ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must enforce the limit of three consecutive invalid logon attempts by a user."
    $VULN = "V-256379"
    $CAT = "II"
    $TEST =  ( Get-VMHost $h | Get-AdvancedSetting -Name Security.AccountLockFailures ).Value
    If ( $TEST -eq "3" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "3" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must enforce an unlock timeout of 15 minutes after a user account is locked out."
    $VULN = "V-256380"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Security.AccountUnlockTime ).Value
    If ( $TEST -eq "900" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "900" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must display the Standard Mandatory DOD Notice and Consent Banner before granting access to the system via the Direct Console User Interface (DCUI)."
    $VULN = "V-256381"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Annotations.WelcomeMessage ).Value
    If ( $TEST -ne "" ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t!Output too long!: Console Banner" # $TEST"

    $RuleTitle = "The ESXi host must display the Standard Mandatory DOD Notice and Consent Banner before granting access to the system via Secure Shell (SSH)."
    $VULN = "V-256382"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Config.Etc.issue ).Value
    If ( $TEST -ne "" ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t!Output too long!: SSH Banner" # $TEST"

    $RuleTitle = "The ESXi host Secure Shell (SSH) daemon must use FIPS 140-2 validated cryptographic modules to protect the confidentiality of remote access sessions."
    $VULN = "V-256384"
    $CAT = "II"
    $TEST = ( ( Get-EsxCli -v2 -VMHost $h ).system.security.fips140.ssh.get.invoke() ).Enabled
    If ( $TEST -eq "true" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "true" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t!Output too long!: FIPS module output" # $TEST"

    $RuleTitle = "The ESXi host must produce audit records containing information to establish what type of events occurred."
    $VULN = "V-256396"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Config.HostAgent.log.level ).Value
    If ( $TEST -eq "info" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "info" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must be configured with a sufficiently complex password policy."
    $VULN = "V-256397"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Security.PasswordQualityControl ).Value
    If ( $TEST -eq "similar=deny retry=3 min=disabled,disabled,disabled,disabled,15" ) {
        $Finding = $False
    }    Elseif ( $TEST -ne "similar=deny retry=3 min=disabled,disabled,disabled,disabled,15" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must prohibit the reuse of passwords within five iterations."
    $VULN = "V-256398"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Security.PasswordHistory ).Value
    If ( $TEST -eq "5" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "5" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must disable the Managed Object Browser (MOB)."
    $VULN = "V-256399"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Config.HostAgent.plugins.solo.enableMob ).Value
    If ( $TEST -eq "False" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "False" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must be configured to disable nonessential capabilities by disabling Secure Shell (SSH)."
    $VULN = "V-256400"
    $CAT = "II"
    $TEST = ( Get-VMHost $h | Get-VMHostService | Where-Object {$_.Label -eq 'SSH'} ).Running
    If ( $TEST -eq $False ) {
        $Finding = $False
    }    Elseif ( $TEST -eq $True ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must disable ESXi Shell unless needed for diagnostics or troubleshooting."
    $VULN = "V-256401"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-VMHostService | Where-Object {$_.Label -eq "ESXi Shell"} ).Running
    If ( $TEST -ne $False ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq $True ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "ESXi hosts using Host Profiles and/or Auto Deploy must use the vSphere Authentication Proxy to protect passwords when adding themselves to Active Directory."
    $VULN = "V-256403"
    $CAT  = "II"
    $TEST = Get-VMHost $h | Select-Object Name, `
        @{ N="HostProfile"; E={ $_ | Get-VMHostProfile } }, `
        @{ N="JoinADEnabled"; E={ ( $_ | Get-VmHostProfile ).ExtensionData.Config.ApplyProfile.Authentication.ActiveDirectory.Enabled } }, `
        @{ N="JoinDomainMethod"; E={ ( ( $_ | Get-VMHostProfile ).ExtensionData.Config.ApplyProfile.Authentication.ActiveDirectory |
        Select-Object -ExpandProperty Policy | Where-Object { $_.Id -eq "JoinDomainMethodPolicy" } ).Policyoption.Id } }
    If ( $null -eq $TEST.HostProfile ) {
        $Finding = $False
    }
    Elseif ( ( $Test.JoinADEnabled -eq "True" ) -and ( $Test.JoinDomainMethod -eq "FixedCAMConfigOption" ) ) {
        $Finding = $False
    }
    Elseif ( ( $Test.JoinADEnabled -eq "True" ) -and ( $Test.JoinDomainMethod -ne "FixedCAMConfigOption" ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "Active Directory ESX Admin group membership must not be used when adding ESXi hosts to Active Directory."
    $VULN = "V-256404"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Config.HostAgent.plugins.hostsvc.esxAdminsGroup ).Value
    If ( $TEST -ne "ESX Admins" ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "ESX Admins" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must set a timeout to automatically disable idle shell sessions after two minutes."
    $VULN = "V-256405"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name UserVars.ESXiShellInteractiveTimeOut ).Value
    If ( $TEST -eq "120" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "120" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must terminate shell services after 10 minutes."
    $VULN = "V-256406"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name UserVars.ESXiShellTimeOut ).Value
    If ( $TEST -eq "600" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "600" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must log out of the console UI after two minutes."
    $VULN = "V-256407"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name UserVars.DcuiTimeOut ).Value
    If ( $TEST -eq "120" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "120" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must enable a persistent log location for all locally stored logs."
    $VULN = "V-256408"
    $CAT  = "II"
    $TEST = ( ( Get-EsxCli -v2 -VMHost $h ).system.syslog.config.get.Invoke() | Select-Object LocalLogOutput,LocalLogOutputIsPersistent ).LocalLogOutputIsPersistent
    If ( $TEST -eq "true" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "true" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must configure NTP time synchronization."
    $VULN = "V-256409"
    $CAT  = "II"
    $TEST1 = Get-VMHost $h | Get-VMHostNTPServer
    $TEST2 = ( Get-VMHost $h | Get-VMHostService | Where-Object {$_.Label -eq "NTP Daemon"} ).Policy
    If ( ( $TEST1 -eq "_IpAddress_" ) -and ( $TEST2 -eq "on" ) ) {
        $Finding = $False
    }
    Elseif ( ( $TEST1 -ne "_IpAddress_" ) -or ( $TEST2 -ne "on" ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST1, $TEST2"

    $RuleTitle = "The ESXi Image Profile and vSphere Installation Bundle (VIB) acceptance levels must be verified."
    $VULN = "V-256410"
    $CAT  = "I"
    $TEST = ( ( Get-EsxCli -v2 -VMHost $h ).software.acceptance.get.Invoke() )
    If ( $TEST -ne "CommunitySupported" ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "CommunitySupported" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "Simple Network Management Protocol (SNMP) must be configured properly on the ESXi host."
    $VULN = "V-256414"
    $CAT  = "II"
    $TEST = ( Get-VMHostSnmp | Select-Object Enabled ).Enabled
    If ( $TEST -eq "False" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "False" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must enable bidirectional Challenge-Handshake Authentication Protocol (CHAP) authentication for Internet Small Computer Systems Interface (iSCSI) traffic."
    $VULN = "V-256415"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-VMHostHba | Where-Object {$_.Type -eq "iscsi"} | Select-Object AuthenticationProperties -ExpandProperty AuthenticationProperties ).MutualChapEnabled
    If ( $TEST -ne "False" ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "False" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must disable Inter-Virtual Machine (VM) Transparent Page Sharing."
    $VULN = "V-256416"
    $CAT  = "III"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Mem.ShareForceSalting ).Value
    If ( $TEST -eq "2" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "2" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must configure the firewall to restrict access to services running on the host."
    # Note: Test returns list of boolean values, if ANY return is $True this is a finding.
    $VULN = "V-256417"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-VMHostFirewallException | Where-Object { $_.Enabled -eq $True } |
        Select-Object Name, Enabled, @{ N="AllIPEnabled"; E={ $_.ExtensionData.AllowedHosts.AllIP } } ).AllIPEnabled
    If ( -Not ( $TEST.Contains( $True ) ) ) {
        $Finding = $False
    }
    Elseif ( $TEST.Contains( $True ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t!Output too long!: Firewall Exceptions" #Test Value: $TEST"
    
    $RuleTitle = "The ESXi host must configure the firewall to block network traffic by default."
    $VULN = "V-256418"
    $CAT  = "II"
    $TEST1 = ( Get-VMHost $h | Get-VMHostFirewallDefaultPolicy ).IncomingEnabled
    $TEST2 = ( Get-VMHost $h | Get-VMHostFirewallDefaultPolicy ).OutgoingEnabled
    If ( ( $TEST1 -eq $False ) -and ( $TEST2 -eq $False ) ) {
        $Finding = $False
    }
    Elseif ( ( $TEST1 -eq $True ) -or ( $TEST2 -eq $True ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST1, $TEST2"
    
    $RuleTitle = "The ESXi host must enable Bridge Protocol Data Units (BPDU) filter on the host to prevent being locked out of physical switch ports with Portfast and BPDU Guard enabled."
    $VULN = "V-256419"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Net.BlockGuestBPDU ).Value
    If ( $TEST -eq "1" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "1" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "All port groups on standard switches must be configured to reject forged transmits."
    # Note: Test returns list of boolean values, if ANY return is $True this is a finding.
    $VULN = "V-256420"
    $CAT  = "II"
    $TEST1 = ( Get-VirtualSwitch -Standard | Get-SecurityPolicy ).ForgedTransmits
    $TEST2 = ( Get-VirtualPortGroup -Standard | Get-SecurityPolicy ).ForgedTransmits
    If ( ( -Not ( $TEST1.Contains( $True ) ) ) -and ( -Not ( $TEST2.Contains( $True ) ) ) ) {
        $Finding = $False
    }
    Elseif ( ( $TEST1.Contains( $True ) ) -or ( $TEST2.Contains( $True ) ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST1, $TEST2"

    $RuleTitle = "All port groups on standard switches must be configured to reject guest Media Access Control (MAC) address changes."
    $VULN = "V-256421"
    $CAT  = "I"
    $TEST1 = ( Get-VirtualSwitch -Standard | Get-SecurityPolicy ).MacChanges
    $TEST2 = ( Get-VirtualPortGroup -Standard | Get-SecurityPolicy ).MacChanges
    If ( ( -Not ( $TEST1.Contains( $True ) ) ) -and ( -Not ( $TEST2.Contains( $True ) ) ) ) {
        $Finding = $False
    }
    Elseif ( ( $TEST1.Contains( $True ) ) -or ( $TEST2.Contains( $True ) ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST1, $TEST2"
    
    $RuleTitle = "All port groups on standard switches must be configured to reject guest promiscuous mode requests."
    $VULN = "V-256422"
    $CAT  = "II"
    $TEST1 = ( Get-VirtualSwitch -Standard | Get-SecurityPolicy ).AllowPromiscuous
    $TEST2 = ( Get-VirtualPortGroup -Standard | Get-SecurityPolicy ).AllowPromiscuous
    If ( ( -Not ( $TEST1.Contains( $True ) ) ) -and ( -Not ( $TEST2.Contains( $True ) ) ) ) {
        $Finding = $False
    }
    Elseif ( ( $TEST1.Contains( $True ) ) -or ( $TEST2.Contains( $True ) ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST1, $TEST2"
    
    $RuleTitle = "Use of the dvFilter network application programming interfaces (APIs) must be restricted."
    $VULN = "V-256423"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Net.DVFilterBindIpAddress ).Value
    If ( $TEST -eq "" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "All port groups on standard switches must be configured to a value other than that of the native virtual local area network (VLAN)."
    $VULN = "V-256424"
    $CAT  = "II"
    $TEST = ( Get-VirtualPortGroup -Standard | Select-Object Name, VLanId ).VLanId
    If ( -Not ( $TEST.Contains( 0 ) ) ) {
        $Finding = $False
    }
    Elseif ( $TEST.Contains( 0 ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "All port groups on standard switches must not be configured to virtual local area network (VLAN) 4095 unless Virtual Guest Tagging (VGT) is required."
    $VULN = "V-256425"
    $CAT  = "II"
    $TEST = ( Get-VirtualPortGroup -Standard | Select-Object Name, VLanId ).VLanId
    If ( -Not ( $TEST.Contains( 4095 ) ) ) {
        $Finding = $False
    }
    Elseif ( $TEST.Contains( 4095 ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

<###    Need to determine what are 'Reserved VLANs' for test.
    $RuleTitle = "All port groups on standard switches must not be configured to virtual local area network (VLAN) values reserved by upstream physical switches."
    $VULN = "V-256426"
    $CAT  = "II"
    $TEST = ( Get-VirtualPortGroup -Standard | Select Name, VLanId ).VLanId
    If ( -Not ( $TEST.Contains(  ) ) ) {
        $Finding = $False
    }
    Elseif ( $TEST.Contains(  ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
###>

    $RuleTitle = "The ESXi host must exclusively enable Transport Layer Security (TLS) 1.2 for all endpoints."
    $VULN = "V-256429"
    $CAT  = "I"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name UserVars.ESXiVPsDisabledProtocols ).Value
    If ( $TEST.Equals("sslv3,tlsv1,tlsv1.1") ) {
        $Finding = $False
    }
    Elseif ( -Not ( $TEST.Equals("sslv3,tlsv1,tlsv1.1") ) ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must not suppress warnings that the local or remote shell sessions are enabled."
    $VULN = "V-256432"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name UserVars.SuppressShellWarning ).Value
    If ( $TEST -eq "0" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "0" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must not suppress warnings about unmitigated hyperthreading vulnerabilities."
    $VULN = "V-256433"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name UserVars.SuppressHyperthreadWarning ).Value
    If ( $TEST -eq "0" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "0" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host OpenSLP service must be disabled."
    $VULN = "V-256435"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-VMHostService | Where-Object {$_.Label -eq "slpd"} ).Policy
    If ( $TEST -eq "off" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "off" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must enable audit logging."
    # Notes: Need to determine what the correct location for lab should be.
    $VULN = "V-256436"
    $CAT  = "II"
    $TEST = ( ( Get-EsxCli -v2 -VMHost $h ).system.auditrecords.get.invoke() ).AuditRecordStorageDirectory
    If ( $TEST -eq "Blah" ) {
        $Finding = $False
    }
    Elseif ( $TEST -eq "/scratch/auditLog" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must enable strict x509 verification for SSL syslog endpoints."
    $VULN = "V-256437"
    $CAT  = "II"
    $TEST = ( Get-EsxCli -v2 -VMHost $h ).system.syslog.config.get.invoke().StrictX509Compliance
    If ( $TEST -eq "true" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "true" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must verify certificates for SSL syslog endpoints."
    $VULN = "V-256438"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Syslog.global.logCheckSSLCerts ).Value
    If ( $TEST -eq $True ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne $True ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must enable volatile key destruction."
    $VULN = "V-256439"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Mem.MemEagerZero ).Value
    If ( $TEST -eq 1 ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne 1 ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must configure a session timeout for the vSphere API."
    $VULN = "V-256440"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Config.HostAgent.vmacore.soap.sessionTimeout ).Value
    If ( $TEST -eq 30 ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne 30 ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi Host Client must be configured with a session timeout."
    $VULN = "V-256441"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name UserVars.HostClientSessionTimeout ).Value
    If ( $TEST -eq 600 ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne 600 ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host rhttpproxy daemon must use FIPS 140-2 validated cryptographic modules to protect the confidentiality of remote access sessions."
    $VULN = "V-256442"
    $CAT  = "II"
    $TEST = ( ( Get-EsxCli -v2 -VMHost $h ).system.security.fips140.rhttpproxy.get.invoke() ).Enabled
    If ( $TEST -eq "True" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "True" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must be configured with an appropriate maximum password age."
    $VULN = "V-256443"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-AdvancedSetting -Name Security.PasswordMaxDays ).Value
    If ( $TEST -eq 90 ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne 90 ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"

    $RuleTitle = "The ESXi host must require TPM-based configuration encryption."
    $VULN = "V-256446"
    $CAT  = "II"
    $TEST = ( ( Get-EsxCli -v2 -VMHost $h ).system.settings.encryption.get.invoke() ).Mode
    If ( $TEST -eq "TPM" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "TPM" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi host must implement Secure Boot enforcement."
    $VULN = "V-256447"
    $CAT  = "II"
    $TEST = ( ( Get-EsxCli -v2 -VMHost $h ).system.settings.encryption.get.invoke() ).RequireSecureBoot
    If ( $TEST -eq "true" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "true" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
    
    $RuleTitle = "The ESXi Common Information Model (CIM) service must be disabled."
    $VULN = "V-256448"
    $CAT  = "II"
    $TEST = ( Get-VMHost $h | Get-VMHostService | Where-Object { $_.Label -eq "CIM Server" } ).Policy
    If ( $TEST -eq "off" ) {
        $Finding = $False
    }
    Elseif ( $TEST -ne "off" ) {
        $Finding = $True
        Add-Vuln $CAT $VULN $RuleTitle
    }
    Else {
        $Finding = $Error[0]
    }
    Write-Log $lInfo "$h`t$CAT`t$VULN`t$Finding`t$TEST"
}
Remove-PSDrive -Name NETAPP_LUN_1 > $null

Write-Host "`n"
If ( $sVerbose -ge 1 ) {
    Write-Log $lInfo "### End executing $sLogName Version: $sScriptVersion"
    $StopWatch.Stop()
    Write-Log $lInfo "Script: $( $sLogName ) executed in: $( $StopWatch.Elapsed.Minutes )m:$( $StopWatch.Elapsed.Seconds )s`n"
    $StopWatch.Reset()
}

$Report = Import-Csv -Delimiter "`t" -Path .\20230511_Scan-ESXi.log -Header Date, Flag, Host, CAT, Vuln, Finding, Value

$cIFind   = $Report | Where-Object { ( $_.Finding -eq "True" -and $_.CAT -eq "I"   ) }
$cIIFind  = $Report | Where-Object { ( $_.Finding -eq "True" -and $_.CAT -eq "II"  ) }
$cIIIFind = $Report | Where-Object { ( $_.Finding -eq "True" -and $_.CAT -eq "III" ) }
Write-Host "`nThere are $($cIFind.Count) Unique: CAT I Findings"
$cIFind   | Format-Table
Write-Host "`nThere are $($cIIFind.Count) Unique: CAT II Findings"
$cIIFind  | Format-Table
Write-Host "`nThere are $($cIIIFind.Count) Unique: CAT III Findings`n"
$cIIIFind | Format-Table
