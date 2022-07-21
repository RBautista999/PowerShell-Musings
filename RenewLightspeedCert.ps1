<# function Test-ForAdmin {
    $RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

} #>



# Check if running with Administrative privileges
$RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($RunningAsAdmin -eq $false) {
    Write-Error "Script requires elevation, please re-run as Administrator" -Category AuthenticationError -RecommendedAction "Please re-run script with elevation"
    break
}

$CertAgeThreshold = 90
$RootStore = 'Cert:\LocalMachine\Root'
$CheckCert = Get-ChildItem -Path $RootStore | Where-Object { $_.Subject -like "*Lightspeed*" }

if ($null -eq $CheckCert) {
    Write-Warning "Could not find Lightspeed Systems certificate in Root Store, if this is in error, please verify Lightspeed Systems Smart Agent is installed. Exiting from script"
    break
}
else {
    switch (($CheckCert | Measure-Object).Count) {
        1 { Write-Output "*Looks like we found a certificate, checking its expiry date" }
        { $_ -ge 2 } { Write-Output "Please check search paramter, variable contains more than one object"; break }
        Default {}
    }
}

if ($CheckCert.NotAfter -lt (Get-Date).AddDays($CertAgeThreshold) ) {
    $TEMP = $env:TEMP
    $LSSAPEM = 'LSSAPEM'
    # $PEMDIR = $TEMP + '\' + $LSSAPEM
    $PEMDIR = Join-Path $TEMP $LSSAPEM
    Write-Output "*Lightspeed Systems Root Certificate is either expired or expiring in the next $($CertAgeThreshold) Days"
    Start-Sleep -Seconds 1
    Write-Output "*Creating temporary certificate folder"
}

else {
    Write-Output "*Lightspeed Systems Root Certificate currently does not require renewal, it expires on the following date: $($CheckCert.NotAfter)"
    Start-Sleep -Seconds 1
    Write-Output "*Will need to roll everything into various functions on a later date, allowing force regeneration of root certificate. But for now, exiting script"
    break
}
if (!(Test-path -path $PEMDIR)) {
    try {      
        $FolderParams = @{
            'Path'     = $Temp
            'Name'     = $LSSAPEM
            'ItemType' = "Directory"
        }
        New-Item @FolderParams
    }
    catch {
        "Unable to create directory in Temp folder, please investigate"
        break
    }

}
else {
    Write-Output "The $($LSSAPEM) is already present in the TEMP folder, proceeding with certificate generation"
}


    
Write-Output "*Generating new certificates"
$LSSACA = "C:\Program Files\Lightspeed Systems\Smart Agent\makeca.exe"
$LSSARootDir = "C:\Program Files\Lightspeed Systems\Smart Agent"
$LSSAArgs = "-dir $($PEMDIR)"

try {
    cmd.exe /C '"C:\Program Files\Lightspeed Systems\Smart Agent\makeca.exe" -dir %TEMP%\LSSAPEM\'
               
}
catch {
    [System.InvalidOperationException]
    "Script is unable to locate Lightspeed's 'makeca' application, is Smart Agent installed correctly?"
    Start-Sleep -Seconds 1
    "Exiting from script, please re-install Relay Smart Agent"
    break
}
  



if ( Test-Path -Path "$PEMDIR\*.pem" ) {
    Write-Output "*The 'makeca' application successfully generated new certificates"
    Start-Sleep -Seconds 1
    Write-Output "*Replacing old certificates in Smart Agent directory"
}
else {
    Write-Error -Message "Looks like 'makeca' was unable to generate new certificates, exiting from script"
    break
}

#Moving certificates from Temp folder to Lightspeed Folder
try {
    cmd.exe /C 'move /y %TEMP%\LSSAPEM\*.pem "C:\Program Files\Lightspeed Systems\Smart Agent"'
    
}
catch {
    "Something went wrong, please troubleshoot"
    break
}

#Checking if LSSASvc service is running
if ((Get-Service -Name LSSASvc).Status -eq "Running") {
    Write-Output "*Stopping the 'LSSASvc' service"
    Start-Sleep -Seconds 1
    Stop-Service -Name LSSASvc -Force -PassThru
}
else {
    Write-Output "*The 'LSSASvc' is not running, proceeding"
}
#Importing new Lightspeed Systems certificate 
try {
    $CAPEM = 'ca.pem'
    Write-Output "*Importing certificates into Root Store"
    Import-Certificate -FilePath "$LSSARootDir\$CAPEM" -CertStoreLocation $RootStore -Confirm

}
catch {
    "Something happen, will need to add information on a later date"
    
}
#Starting LSSASvc service
if ((Get-Service -Name LSSASvc).Status -eq "Stopped") {
    Write-Output "*Starting the 'LSSASvc' service"
    Start-Sleep -Seconds 1
    Start-Service -Name LSSASvc -PassThru
}
#One final check of new certificate in store
$CheckNewCert = Get-ChildItem -Path $RootStore | Where-Object { $_.Subject -like "*Lightspeed*" }
if ($CheckNewCert.NotAfter -lt (Get-Date).AddDays($CertAgeThreshold) ) {
    Write-Output "*Certificate renewal process was successful, please try browsing the internet"
}
