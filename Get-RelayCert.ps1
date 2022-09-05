$ErrorActionPreference = "Stop"

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