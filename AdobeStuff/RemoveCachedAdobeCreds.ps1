$ErrorActionPreference = "Stop"

#Get Adobe processes
$AdobeProcs = Get-Process | Where-Object { $_.Company -like "*Adobe*" }
#Print Processes that are about to get forcefully stopped
Write-Output "*These are the following Adobe processes that will be stopped: $($AdobeProcs.ProcessName)"
#Stop Process
$AdobeProcs | Stop-Process
#Checking to see if 'SLCache' folder exists on workstation
$SLCache = 'C:\Program Files (x86)\Common Files\Adobe\SLCache'

if ( Test-Path $SLCache ) {
    Write-Output "*Found 'SLCache' folder on this workstation"
    try {
        Write-Output "*Removing contents of 'SLCache' folder"
        Get-ChildItem -Path $SLCache -Include * -Recurse -Force | Remove-Item
    }
    catch {
        $Message = $_
        Write-Warning -Message "Something went wrong! $Message"
    }
}
else {
    Write-Output "*This workstation does not appear to have the 'SLCache' folder, is Adobe Creative Cloud installed?"
    break
}

$SLStore = 'C:\ProgramData\Adobe\SLStore'

if ( Test-Path $SLStore ) {
    Write-Output "*Found 'SLStore' folder on this workstation"
    try {
        Write-Output "*Removing contents of 'SLStore' folder"
        Get-ChildItem -Path $SLStore -Include * -Recurse -Force | Remove-Item
    }
    catch {
        $Message = $_
        Write-Warning -Message "Something went wrong! $Message"
        
    }
}
else {
    Write-Output "*This workstation does not appear to have the 'SLStore' folder, is Adobe Creative Cloud installed?"
    break
}

#Get all users
$UserPath = 'C:\Users'
$Users = Get-ChildItem -Path $UserPath

foreach ($User in $Users.Name) {
    $UserProfile = Join-Path $UserPath $User
    $OOBEPath = 'AppData\Local\Adobe\OOBE'
    $AdobeUserPath = Join-Path $UserProfile $OOBEPath

    if ( Test-Path $AdobeUserPath ) {
        Write-Output "*$($User.FullName) has 'OOBE' folder in their userprofile"
        try {
            Write-Output "*Removing contents of 'OOBE' folder from $($User.FullName)'s userprofile"
            Get-ChildItem -Path $AdobeUserPath -Include * -Recurse -Force | Remove-Item
        }
        catch {
            $Message = $_
            Write-Warning -Message "Something went wrong! $Message"
        }
    }
    else {
        Write-Warning "$($User.FullName) doesn't have an OOBE folder, skipping"
    }
}

