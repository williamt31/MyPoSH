Function Menu () {
    param ( [string]$Title = ' ---- User Profile Migration Tool ' )
    $Selection
    #Clear-Host
    Write-Host "  =====$Title====="
    Write-Host ""
    Write-Host "`t(B)ackup User Profile"
    Write-Host "`t(R)estore User Profile"
    Write-Host "`t(Q)uit"
}

Function BackupU () {
    $UserDirs = Get-ChildItem -Directory -Path "C:\Users"
    $Menu = @{}
    for ( $i=1 ; $i -le $UserDirs.Count ; $i++ ) {
        Write-Host "$i. $( $UserDirs[ $i-1 ].Name)"
        $Menu.Add( $i,( $UserDirs[$i-1].Name ) )
        }

    [Int]$Ans = Read-Host 'Select User Folder: '
    $Selection = $Menu.Item( $Ans )
    $SelectDir = $( "C:\Users\" + "$Selection" )
    $BackupDir = $( "C:\Users\" + "$Selection" + ".bak" )
    Write-Host "`nRenaming: $SelectDir to $BackupDir"

    # Update registry profile path
#    $ProfilePath = ( Get-ChildItem -Recurse "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\ProfileList" | Get-ItemProperty | Where-Object { $_.ProfileImagePath -eq $SelectDir } ).PsPath
#    Set-ItemProperty -Path $ProfilePath -Name "ProfileImagePath" -Value $BackupDir

    # Rename UserProfile to .bak
#    Move-Item -Path $SelectDir -Destination $BackupDir -Force
}

Function RestoreU () {
    $UserDirs = Get-ChildItem -Directory -Path "C:\Users"
    $Menu = @{}
    for ( $i=1 ; $i -le $UserDirs.Count ; $i++ ) {
        Write-Host "$i. $( $UserDirs[ $i-1 ].Name)"
        $Menu.Add( $i,( $UserDirs[$i-1].Name ) )
        }

    [Int]$Ans = Read-Host 'Select User Folder: '
    $Selection = $Menu.Item( $Ans )
    $SelectDir = $( "C:\Users\" + "$Selection" )
    #Write-Host $Selection
    $RestoreDir   = $( "C:\Users\" + $( $Selection ).SubString( 0,$Selection.IndexOf( "WI" )) )
    Write-Host "`nMoving files from: $SelectDir to $RestoreDir"

    $DataDirs = ".ssh",".vscode","Desktop","Documents","Downloads","Logs"
    Foreach ( $Dir in $DataDirs ) {
        If ( Test-Path -Path $( $BackupDir + "\" + $Dir ) ) {
        #    $RoboArgs = @( $BackupDir\$Dir, $RestoreDir\$Dir , "/E", "/MIR", "/R:1", "/W:1", "/nc", "/nfl", "/ndl", "/np", "/njh", "/njs", "/A-:R" )
        #    $ExitCode = ( Start-Process -FilePath Robocopy -ArgumentList $RoboArgs -Wait -PassThru ).ExitCode

        #    Write-Host $( $RestoreDir + "\" + $Dir )
        }
    }
}


Menu
$selection = Read-Host "`n`tPlease make a selection"
Switch ( $Selection ) {
    'B' { BackupU }
    'R' { RestoreU }
    'Q' { Exit }
}
