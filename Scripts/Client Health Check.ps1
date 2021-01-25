# Author Notes
# williamt31
# Engineering Operations
$Version = "2018.10.18"

####################################################################################################
# Begin Setting Variables
# Setting Current Version of Applications
$Cur_VER_BF = "9.5.9.62"
$Cur_VER_VPN = "4.4.4030.0"
$Cur_VER_MIP = "8.8.5.0"
$Cur_VER_SCCM = "5.0.8634.1000"
$Cur_Ver_SEP = "14.0.3929.1200"
    
# Setting Path Variables
$App_Loc_BF = 'C:\Program Files (x86)\BigFix Enterprise\BES Client\BESClient.exe'
$App_Loc_VPN = 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnagent.exe'
$App_Loc_MIP = 'C:\Program Files (x86)\Autonomy\Connected BackupPC\ConnectedAgent.exe'
$App_Loc_SCCM = 'C:\Windows\CCM\CcmExec.exe'
$App_Loc_SEP = 'C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\SepLiveUpdate.exe'
$CHC_Path = "C:\ClientHealthCheck"
    
# Setting Service Variables
$Service_Name_BF = "BESClient"
$Service_Name_VPN = "VPNAgent"
$Service_Name_MIP = "AgentService"
$Service_Name_SCCM = "CcmExec"
$Service_Name_SEP = "SepMasterService"

# Getting Windows Version Information
$WinVerMa = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' CurrentMajorVersionNumber).CurrentMajorVersionNumber
$WinVerMi = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' CurrentMinorVersionNumber).CurrentMinorVersionNumber
$WinVerBu = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' CurrentBuild).CurrentBuild
$WinVerUB = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' UBR).UBR
$WinProduct = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' ProductName).ProductName
$RegOrg = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' RegisteredOrganization).RegisteredOrganization
$FullWinVer = "$WinVerMa.$WinVerMi.$WinVerBu.$WinVerUb"
$Windows_Release_ID = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' ReleaseId).ReleaseId

# Get System Information
$System = Get-WmiObject Win32_ComputerSystem -ComputerName . | Select-Object -Property Name,Model,Domain
$BIOS = Get-WmiObject Win32_BIOS -ComputerName . | Select-Object -Property SerialNumber
$Memory = Get-WmiObject Win32_PhysicalMemory -ComputerName . | Select-Object -Property Capacity,Speed,Attributes
$OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName . 
$OEM_RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
$OEM_RegValue = "Model"
$OEM_Model = (Get-ItemProperty -path $OEM_RegKey -name $OEM_RegValue).$OEM_RegValue
$RAM_GB = $Memory.Capacity / 1024/1024/1024
$RAM_Speed = $Memory.Speed
$RAM_Sticks = $Memory.Attributes
$DHCP_IP = Get-NetIPAddress | Where-Object PrefixOrigin -eq dhcp | Select-Object -ExpandProperty IPAddress
$BF_HomeCenter = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\BigFix\EnterpriseClient\Settings\Client\_HomeCenter' value).value
$BF_SecurityPlan = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\BigFix\EnterpriseClient\Settings\Client\_SecurityPlan' value).value
# End Setting Variables
####################################################################################################
# Begin Function Blocks
# Log Folder Test 'C:\ClientHealthCheck'
Function Log_Path_Test(){
    Write-Host "" # Debug blank line
    If(!(Test-Path $CHC_Path)){
        New-Item -ItemType Directory -Force -Path $CHC_Path -ErrorAction Stop  | Out-Null
        Write-Host 'C:\ClientHealthCheck Created Successfully'
        # Insert Code here for Logging
        $Global:Log_Path = $True
    } ELSEIF(Test-Path $CHC_Path){
        Write-Host "Log Directory C:\ClientHealthCheck already exist no change made"
        # Insert Code here for Logging
        $Global:Log_Path = $True
    } ELSE {
        Write-Host "Unable to Create Log Directory"
        # Insert Code here for Logging
        $Global:Log_Path = $False
    }
}

Function Get-Uptime {
    $OS = Get-WmiObject Win32_OperatingSystem
    $Script:UpTime = (Get-Date) - ($OS.ConvertToDateTime($OS.LastBootUpTime))
    $Display = "Time since last Reboot: " + $Uptime.Days + " Days, " + $Uptime.Hours + " Hours, " + $Uptime.Minutes + " Minutes"
    Write-Output $Display
 }

 # Bitlocker Info
 Function BitLocker_Info(){
    $BitLocker_Info = Get-BitLockerVolume  -MountPoint C:
    $Script:BitLocker_Vol_Stat = $BitLocker_Info.VolumeStatus
    $Script:BitLocker_Vol_Enc = $BitLocker_Info.EncryptionPercentage
 }
 

 # Get Service Status
Function Check_Service_Status{
    Param(
   [Parameter(Position=0,Mandatory=$True)]
   [String]$Service_Name)
    Process{
        $Script:Service_Status = Get-Service -Name $Service_Name | Select-Object -Property Status
    }
}

# Asset Number Test
Function Asset_Test(){
    Write-Host "" # Debug blank line
    $Script:AssetTest = ""
    $Script:AssetNumber = $System.Name.SubString(5)    
    While("Y","N" -NotContains $AssetTest){
        $Script:AssetTest = Read-Host "Is the Asset # on your Computer:" $Script:AssetNumber "? (Y)es or (N)o"
        $Script:AssetTest = $AssetTest.ToString().ToUpper()}
        If($Script:AssetTest -eq "N"){
            Write-Host ("`a")
            Write-Host "Please Correct Computer Name per ACES naming convention."
            Write-Host "This window will close in 15 seconds"
            Start-Sleep 15
        } ElseIf($Script:AssetTest -eq "Y"){
    }
}

# Check for Pending Reboots
Function Test_Pending_Reboot(){
    If (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { $Script:Pending_Reboot = $True }
    If (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { $Script:Pending_Reboot = $True }
    If (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { $Script:Pending_Reboot = $True }
    Try { 
        $Util = [WMIClass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
        $Status = $Util.DetermineIfRebootPending()
        If(($Status -ne $Null) -and $Status.RebootPending){
            $Script:Pending_Reboot = $True
        }
    }Catch{}
    $Script:Pending_Reboot = $False
}

# Check Client File Version and if Related Services are Funning
Function Client_Health_Check(){
    If(Test-Path $App_Loc_BF){
        $Script:Inst_Ver_BF = (Get-Command $App_Loc_BF).FileVersionInfo.FileVersion
        [Bool]$Script:File_Check_BigFix = $True
        $Service_Test_BF = Check_Service_Status $Service_Name_BF
        $Script:Service_Test_BF = $Service_Status.Status
    }
    If(Test-Path $App_Loc_VPN){
        $Script:Inst_Ver_VPN = (Get-Command $App_Loc_VPN).FileVersionInfo | Select-Object -Property FileMajorPart,FileMinorPart,FileBuildPart,FilePrivatePart
        $Script:Inst_Ver_VPN = $Inst_Ver_VPN.FileMajorPart,$Inst_Ver_VPN.FileMinorPart,$Inst_Ver_VPN.FileBuildPart,$Inst_Ver_VPN.FilePrivatePart -join "."
        [Bool]$Script:File_Check_VPN = $True
        $Service_Test_VPN = Check_Service_Status $Service_Name_VPN
        $Script:Service_Test_VPN = $Service_Status.Status
    }
    If(Test-Path $App_Loc_SCCM){
        $Script:Inst_Ver_SCCM = (Get-Command $App_Loc_SCCM).FileVersionInfo.FileVersion
        [Bool]$Script:File_Check_SCCM = $True
        $Service_Test_SCCM = Check_Service_Status $Service_Name_SCCM
        $Script:Service_Test_SCCM = $Service_Status.Status
    }
    If(Test-Path $App_Loc_SEP){
        $Script:Inst_Ver_SEP = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Symantec\Symantec Endpoint Protection\CurrentVersion' ProductVersion).ProductVersion
        [Bool]$Script:File_Check_SEP = $True
        $Service_Test_SEP = Check_Service_Status $Service_Name_SEP
        $Script:Service_Test_SEP = $Script:Service_Status.Status
    }
    If(Test-Path $App_Loc_MIP){
        $Script:Inst_Ver_MIP = (Get-Command $App_Loc_MIP).FileVersionInfo.ProductVersion
        [Bool]$Script:File_Check_MIP = $True
        $Script:Service_Test_MIP = Check_Service_Status $Service_Name_MIP
        $Script:Service_Test_MIP = $Script:Service_Status.Status
    }
}

# Client Functionality Tests
Function Client_Health_Test(){
    If(1 -eq 1){Write-Host "Blah"}
}



# System Information Panel
Function System_Info_Panel(){
    Write-Host ""
    Write-Host "`t`tSystem Information`t`t`t`t"
    Write-Host "`t|=======================================================================================|"
    Write-Host "`t|`tMachine Name:`t"   $System.Name"`t`tDomain:`t`t"           $System.Domain.ToUpper()"`t`t|"
    Write-Host "`t|`tSystem Model:`t"   $System.Model"`tBIOs Model:`t"          $OEM_Model"`t`t|"
    Write-Host "`t|`tSerial Num:`t"     $BIOS.SerialNumber"`t`tAsset Num:`t"    $AssetNumber"`t`t|"
    Write-Host "`t|`tFull OS Ver:`t"    $FullWinVer"`tOrganization:`t"          $RegOrg"`t`t|"
    Write-Host "`t|`tOS Product:`t"     $WinProduct"`tTotal RAM:`t"             $RAM_GB"`t`t`t|"
    Write-Host "`t|`tOS Release:`t"     $Windows_Release_ID"`t`t`tRAM Speed:`t" $RAM_Speed"`t`t`t|"
    Write-Host "`t|`tNetwork IP:`t"     $DHCP_IP"`t`tRAM Sticks:`t"             $RAM_Sticks"`t`t`t|"
    Write-Host "`t|`tBitLocker Status:" $BitLocker_Vol_Stat"`t% Encrypted:`t"   $BitLocker_Vol_Enc"`t`t`t|"
    Write-Host "`t|=======================================================================================|"
    Write-Host ""
}

#;""=;""=;""=;""=;""=;""=;""=


# Application Information
Function Client_Health_Panel(){
    Write-Host ""
    Write-Host "`t|===============================================================================================|"
    Write-Host "`t|`tApplication`tCurrent Vertion`t`tInstalled Version`tIs Current`tService |"
    Write-Host "`t|`t-----------`t---------------`t`t-----------------`t----------`t------- |"
    Write-Host "`t|`tCisco VPN`t$Cur_VER_VPN`t`t$Inst_Ver_VPN`t`t$File_Check_VPN`t`t$Service_Test_VPN |"
    Write-Host "`t|`tMIP Backup`t$Cur_VER_MIP`t`t`t$Inst_Ver_MIP`t`t`t$File_Check_MIP`t`t$Service_Test_MIP |"
    Write-Host "`t|`tSCCM`t`t$Cur_VER_SCCM`t`t$Inst_Ver_SCCM`t`t$File_Check_SCCM`t`t$Service_Test_SCCM |"
    Write-Host "`t|`tSymantec`t$Cur_Ver_SEP`t`t$Inst_Ver_SEP`t`t$File_Check_SEP`t`t$Service_Test_SEP |"
    Write-Host "`t|`tBigFix`t`t$Cur_VER_BF`t`t$Inst_Ver_BF`t`t$File_Check_BigFix`t`t$Service_Test_BF |"
    Write-Host "`t|`t`t`t`t`t`t`t`t`t`t`t`t|"
    Write-Host "`t|`tSecurity Plan:`t$BF_SecurityPlan`tBigFix HomeCenter:`t$BF_HomeCenter`t`t|"
    Write-Host "`t|===============================================================================================|"
    Write-Host ""
}

# End Function Blocks
$UpTime_Check = Get-UpTime
####################################################################################################
Log_Path_Test # Keep this First
Asset_Test
Client_Health_Check
Client_Health_Test
Test_Pending_Reboot
BitLocker_Info
# Start Health Check
#Clear-Host
Write-Host ""
Write-Host "`t`tClient Health Check`t`tVersion: $Version"
Write-Host "`t`t$UpTime_Check`t`t`t`t`t"
Write-Host "`t`tIs This Computer Pending a Reboot?: $Pending_Reboot"
Write-Host ""
System_Info_Panel
Client_Health_Panel

$LogFile = Get-Date -Format "yyyy-MM-dd_hh-mm_"
$LogFile = $CHC_Path+"\"+$LogFile+$System.Name+".csv"
$CHC_Variables | export-csv -Path $LogFile -NoTypeInformation -NoClobber