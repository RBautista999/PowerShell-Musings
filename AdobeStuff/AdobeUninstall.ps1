$Apps = @()
$32BitPath = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$64BitPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

Write-Host "Getting installed applications"
$Apps += Get-ItemProperty "HKLM:\$32BitPath"
$Apps += Get-ItemProperty "HKLM:\$64BitPath"

$Adobe = $Apps | Where-Object { $_.Publisher -like "*Adobe*" }

foreach ($UninstallString in $Adobe.UninstallString){
    $Executable = $UninstallString.split('"')[0]
    $Paramaters = $UninstallString.split('"')[1]

    Start-Process -FilePath $Executable -ArgumentList $Paramaters
}
