# Source: https://www.computerperformance.co.uk/powershell/create-shortcut/
# Create a Calculator Shortcut with Windows PowerShell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\Calc.lnk")
$Shortcut.TargetPath = "Calc"
$Shortcut.Save()
