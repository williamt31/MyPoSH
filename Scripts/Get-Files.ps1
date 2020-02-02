# Just a simple script to get a list of files using a filter and custom output.

Get-ChildItem -Recurse | 
	Where-Object { (($_.Length /1MB) -ge 400) } | 
	Select-Object `
	@{n="Name";e={$_.Name}},
	@{n="Year";e={Get-Date $_.LastWriteTime -Format 'yyyy'}},
	@{n="File Size GB";e={[math]::Round($_.Length/1GB,2)}} |
	Export-Csv -NoTypeInformation c:\temp\files_list.csv
