# Code to open a (Windows) file dialog box and get a list of Hostnames regardless of whether it's a text or csv file.

Function Get-File ( $GetWhat ) {
    Add-Type -AssemblyName System.Windows.Forms
    $GetFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        Title = "Select input for $GetWhat"
        InitialDirectory = "C:\"
        Filter = 'CSV (*.csv)|*.csv|Text (*.txt;*.text)|*.txt;*.text|All (*.*)|*.*'
    }
    $null = $GetFile.ShowDialog()
    $FileExt = $GetFile.FileName.Split('.').Length -1
    $sExt = $GetFile.FileName.Split('.')[$FileExt]
    If ( $sExt -eq "txt" -or $sExt -eq "text" ) {
        $Results = Get-Content -Path ( $GetFile ).FileName
        Return $Results, $sExt
    }
    Elseif ( $sExt -eq "csv" ) {
        $Results = Import-Csv -Path ( $GetFile ).FileName
        Return $Results, $sExt
    }
}

# Begin Processing
$GetCompList = Get-File "Computer List"
If ( $GetCompList[1] -eq "csv" ) {
    $Comps = $GetCompList[0].Hostname | Sort-Object -Unique
}
Else {
    $Comps = $GetCompList[0] | Sort-Object -Unique
}

$IPList = Get-File "IP Lookup list"
$IPs = IPList.IP
