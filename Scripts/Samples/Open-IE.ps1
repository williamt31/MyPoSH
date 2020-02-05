# Source: https://docs.microsoft.com/en-us/powershell/scripting/samples/creating-.net-and-com-objects--new-object-?view=powershell-5.1
# Open an IE window, make it visible and navigate to a specific site.

$IE = New-Object -ComObject InternetExplorer.Application
$IE.Visible = $True
$IE.Navigate("www.google.com")
