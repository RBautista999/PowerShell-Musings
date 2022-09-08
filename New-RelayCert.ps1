param (
    <#
    .PARAMETER Clean
    Use this to delete all Relay certs from the Root Store
    #>
    [Parameter()]
    [switch]
    $Clean
)

$ErrorActionPreference = "Stop"
#requires -RunasAdministrator

function Get-Relay {
   
    [CmdletBinding()]
    #[OutputType('Microsoft.Win32.RegistryKey')]
    param (
        # Parameter help description
        [Parameter()]
        [switch]
        $Version,
        [Parameter()]
        [switch]
        $InstallPath
            
    )        
    begin {
        $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $Relay = $InstalledSoftware | Where-Object { $PSItem.GetValue("Publisher") -like "*Lightspeed*" }
         
    }        
    process {
        if ($Version) {
            $Relay.GetValue("DisplayVersion")
        }
        if ($InstallPath) {
            $Relay.GetValue("InstallLocation")
        }   
    }       
    end {   
    
    }    
}

function Get-RelayCert {
    <#
    .SYNOPSIS
        Retrives Relay Smart Agent/Filter Certificate
    .DESCRIPTION
        Use this to determine whether Relay's cert has expired
    .PARAMETER Path
        Used to define path to Certificate Store( if different from default )
    .PARAMETER IncludeDates
        Paramater switch that displays Start & Expiration Dates of Certificate
    .NOTES
        Function will return $null value on machines without Lightspeed
    .EXAMPLE
        Get-RelayCert -IncludeDates
        
        This will display results with 'Issuer, Start Date, and Expiration Date'
    #>
    [CmdletBinding()]
    [OutputType('System.Security.Cryptography.X509Certificates.X509Certificate2')]
    param (
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $False,
            Position = 0)]
        [string]
        $Path = "Cert:\LocalMachine\Root\",
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $False)]
        [switch]
        $IncludeDates    
    )
    $Cert = Get-ChildItem $Path | Where-Object { $_.Subject -like "*Lightspeed*" }
    if ($IncludeDates) {
        $ObjectParams = @{
            Property = "Issuer",
            @{Name = "Start Date"; Expression = { $_.NotBefore } },
            @{Name = "Expiration Date"; Expression = { $_.NotAfter } }
        }
        $Cert | Select-Object @ObjectParams
    }
    else {
        $Cert
    }    
}   

function New-RelayCert {
    param (
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True)]
        [AllowNull()]
        [string]
        $ComputerName       
    )
    begin {
        $RootStore = 'Cert:\LocalMachine\Root'
        $TEMP = $env:TEMP
        $LSSAPEM = 'LSSAPEM'
        $PEMDIR = Join-Path $TEMP $LSSAPEM
        $InstallLocation = Get-Relay -InstallPath
        $CAPEM = 'ca.pem'
        
    }
    process {
        Write-Output "Retrieving current Certificate(s)"
        Start-Sleep -Seconds 2
        Get-RelayCert -IncludeDates
        Start-Sleep -Seconds 2
        Write-Output "Creating temporary cert folder"

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
            Write-Output "Folder present, proceeding"
        }
        try {
            cmd.exe /C '"C:\Program Files\Lightspeed Systems\Smart Agent\makeca.exe" -days 1095 -pause-on-error -dir %TEMP%\LSSAPEM\'
            Start-Sleep -Seconds 2
            if ( Test-Path -Path "$PEMDIR\*.pem" ) {
                Write-Output "*The 'makeca' application successfully generated new certificates"
                Start-Sleep -Seconds 1
                Write-Output "*Moving certificates to program directory"
            }
            cmd.exe /C 'move /y %TEMP%\LSSAPEM\*.pem "C:\Program Files\Lightspeed Systems\Smart Agent"'
            Write-Output "*Importing certificates into Root Store"
            Import-Certificate -FilePath "$InstallLocation\$CAPEM" -CertStoreLocation $RootStore
            Write-Output "Restarting Relay Service"
            Start-Sleep -Seconds 2
            Get-Service -Name LSSASvc | Restart-Service -Force -PassThru 
                       
        }
        catch {
            Write-output "Ran into an issue"
            Start-Sleep -Seconds 1
            Write-output "Exiting from script, consider reinstalling Relay Smart Agent"
            break
        }
        
           
    }
}

if ($Clean) {
    $Reply = Read-Host -Prompt "This action will remove all Relay Certs. Continue? [y/n]"
    if ($Reply -match "[yY]" ) {
        Write-Output "Deleting ALL Relay Certs from Cert Store"
        Start-Sleep -Seconds 2
        $DeleteCerts = Get-RelayCert
        foreach ($Cert in $DeleteCerts) {
            $PSitem | Remove-Item -Force -Verbose -ErrorAction Stop
        }
        Write-Output "Certs have been deleted, proceeding with regeneration"
        Start-Sleep -Seconds 2
        New-RelayCert
    }
    else {
        New-RelayCert
    }
}
else {
    New-RelayCert
}

