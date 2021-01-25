#requires -version 5
<#
.SYNOPSIS
    <Overview of script>
.DESCRIPTION
    <Brief description of script>
    Using Powershell module 'Get-MediaInfo' helps automate obtaining information about your media

.NOTES
    Author:             williamt31
    Creation Date:      20210117
    Version:            Purpose/Change
    ---     --------    --------------
    1.0                 Intial Creation/Modification of Script
    2.0     20210123    Improved Error Capture/Logic Checking

.INPUTS
    <Inputs if any, otherwise state None>
    Needs to know what Dir to process media from
    [Optional]If Minimum size of media is not specified default value of 500MB is used

.OUTPUTS
    <Outputs if any, otherwise state None - example: Log file stored in C:\Windows\Temp\<name>.log>
    Needs to know where to save output of results

.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
    -Path   Directory path of media files to process

.EXAMPLE
    <Example goes here. Repeat this attribute for more than one example>
    Get-MediaInfoScript -Path C:\Movies -Output C:\Movies.csv
#>
[cmdletbinding()]
Param (
    [parameter(mandatory=$false, ValueFromPipeline=$false)][String]$sVersion = "2",    
    [parameter(mandatory=$false, ValueFromPipeline=$true)][String]$MinSize = "500MB",
    [parameter(mandatory=$true, ValueFromPipeline=$true)][String]$Path,
    [parameter(mandatory=$true, ValueFromPipeline=$true)][String]$OutFile,
    [parameter(mandatory=$false, ValueFromPipeline=$true)][Switch]$Detailed,
    [parameter(mandatory=$false, ValueFromPipeline=$true)][Switch]$Full
)
#---------------------------------------------------------[Initialisations]--------------------------------------------------------
# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
# Format Cleanup Declarations
$FileNameShort  = @{ N="FileName"; E={ ( $_.FileName).TrimEnd() }}
$FileSizeGB     = @{ N="FileSizeGB"; E={ [Math]::Round( $_.FileSize/1KB,2 )}}
$DurationMin    = @{ N="DurationMin"; E={ [Math]::Round( $_.Duration,1 )}}

# Format Profiles
$BasicVals      = ( $FileNameShort, $FileSizeGB, $DurationMin, "Height" )
$DetailedVals   = ( $FileNameShort, $FileSizeGB, $DurationMin, "Height", "Width", "Format", "AudioCodec" )
$FullVals       = ( "Directory", $FileNameShort, "Ext", "Format", $FileSizeGB, $DurationMin, "AudioCodec", "BitRate", "BitRate", "Height", "Width", "FormatProfile", "ScanType", "TextFormat", "Transfer", "DAR", "ColorPrimaries" )

#-------------------------------------------------------[Script Functions]----------------------------------------------------------
Function DependancyCheck(){
    If (Get-Module -ListAvailable -Name Get-MediaInfo) {
        Write-Verbose "Dependancy Check Passed"
    } 
    else {
    Write-Host "Missing Dependancy Module 'Get-MediaInfo'"
    Write-Host "Press any key to launch browser to website with Installation Instructions"
    Pause
    Start-Process "https://github.com/stax76/Get-MediaInfo"
    Pause
    Exit
    }
}

#-------------------------------------------------------[Main Function]----------------------------------------------------------
Function Get-MediaInfoScript(){

    If (!($OutFile.Split('.')[1] -eq "csv")){
        $OutFile = $OutFile.Split('.')[0] + ".csv"
    }   Write-Verbose "Outfile: $OutFile"

    $MinSizeEnd = $MinSize.SubString($MinSize.Length -2)
    While (!( $MinSizeEnd -eq "MB" -or  $MinSizeEnd -eq "GB" )){
        Write-Host "$MinSize isn't a proper size notation"
        $MinSize = Read-Host -Prompt 'Enter a Valid File Size ex. "500MB or 1GB etc"'
        $MinSizeEnd = $MinSize.SubString($MinSize.Length -2)
    }   Write-Verbose "Minimum Media Size Constraint: $MinSize"

    While (!(Test-Path $Path)){
        Write-Host "$Path Isn't a valid Path"
        $Path = Read-Host -Prompt 'Enter a Valid Path'
    }   Write-Verbose "Path to Media to be Scanned: $Path"

    # Return Value Collections
If( $Detailed ){ 
    $ObtainedVals = $DetailedVals
}
ElseIf( $Full ){
    $ObtainedVals = $FullVals
}
else { #Basic
    $ObtainedVals = $BasicVals
}

# Begin Processing
Get-ChildItem -Recurse $Path |
    Where-Object { $_.Length -gt $MinSize } | 
    Get-MediaInfo |
    #Select-Object $ObtainedVals -First 10 | Format-Table #Testing Line
    Export-Csv $OutFile -NoTypeInformation
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
DependancyCheck
Get-MediaInfoScript