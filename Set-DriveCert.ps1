
<# Google Drive for Desktop will break when TLS decryption is utilized, this script aims to rectify that issue.
The issue comes about due to Drive for Desktop using its own root certificate instead of the one used by Smart Agent/Filter.
This script creates a Registry key that points towards the PEM created by Lightspeed Smart Agent/Filter #>



#Checking to see if script is running elevated
$RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($RunningAsAdmin -eq $false) {
    Write-Error "Script requires elevation, please re-run as Administrator" -Category AuthenticationError -RecommendedAction "Please re-run script with elevation"
    
    break
}

<# See the following Google article for information on where the relevant Registry keys are found
https://support.google.com/a/answer/7644837 
#>

$DrivePath = "HKLM:\SOFTWARE\Google\DriveFS"
$SAPEM = "C:\Program Files\Lightspeed Systems\Smart Agent\ca.pem"
$DriveTrustedRoot = "TrustedRootCertsFile"


function Get-DriveCert {
    
    Get-ItemProperty -Path $DrivePath -Name $DriveTrustedRoot -ErrorAction SilentlyContinue
    
}


if (((Test-Path -Path $DrivePath) -eq $True) -and ((Test-Path -Path $SAPEM) -eq $True)) {
    Write-Output "Found Google Drive Registry Entry and Lightspeed CA, proceeding"

    if ( Get-DriveCert ) {
        Write-Output "Registry contains the '$($DriveTrustedRoot)' key, checking to see if it's configured correctly"

        if (((Get-DriveCert).$DriveTrustedRoot) -eq $SAPEM) {
            Write-Output "Registry Key is configured correctly, exiting script"
            break
        }
        else {
            Write-Output "Registry is NOT configured correctly, rectifying..."
            Set-ItemProperty -Path $DrivePath -Name $DriveTrustedRoot -Value $SAPEM

            if (((Get-DriveCert).$DriveTrustedRoot) -eq $SAPEM) {
                Write-Output "Registry Key is now configured correctly, exiting script"
                break
            }
        }
    }

    else {
        Write-Output "Registry does NOT contain '$($DriveTrustedRoot)' key, creating it now"

        try {
            New-ItemProperty -Path $DrivePath -Name $DriveTrustedRoot -Value $SAPEM -PropertyType "String"

            Write-Output "Created Registry Key, exiting script!"
            
            break
            
        }
        catch {
            { Write-Error -Message "Something really bad happened" }
        }
    }
}

else {
    Write-Output "Either Google Drive or the Lightspeed CA is not present, exiting from script"

    Start-Sleep 1
    break   
}


