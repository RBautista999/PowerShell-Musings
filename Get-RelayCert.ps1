$ErrorActionPreference = "Stop"

function Get-RelayCert {
    <#
    .SYNOPSIS
        Retrives Relay Smart Agent/Filter Certificate
    .DESCRIPTION
        Use this to determine whether Relay's cert has expired
    .PARAMETER ComputerName

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
    param (
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $True,
            Position = 0)]
        [string]
        $ComputerName,
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $False,
            Position = 1)]
        [string]
        $Path = "Cert:\LocalMachine\Root\",
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $False)]
        [switch]
        $IncludeDates    
    )
    begin {
        $ObjectParams = @{
            Property = "Issuer",
            @{Name = "Start Date"; Expression = { $_.NotBefore } },
            @{Name = "Expiration Date"; Expression = { $_.NotAfter } }
        }
    
    }
    process {
        if ($ComputerName) {
            $Results = $ComputerName | Foreach-Object -ThrottleLimit 10 -Parallel {
                if (Test-Connection -TargetName $PSItem -Quiet) {
                    Write-Output "Connection to $($PSItem) successful"
                    $RemoteParams = @{
                        ComputerName = $PSItem
                        ScriptBlock  = { Get-ChildItem $args | Where-Object { $_.Subject -like "*Lightspeed*" } }
                        ArgumentList = "Cert:\LocalMachine\Root\"
                    }
                    
                    $GetCert = Invoke-Command @RemoteParams
                    if ($null -eq $GetCert) {
                        Write-Warning "$($PSItem) doesn't have Lightspeed Relay Smart Agent installed"
                    }
                    else {
                        Write-Host "Adding resuts to array" 
                        foreach ($Cert in $GetCert) {
                            [PSCustomObject]@{
                                'Computer'    = $PSItem
                                'Certificate' = $Cert.Issuer
                                'Begins'      = $Cert.GetEffectiveDateString()
                                'Expires'     = $Cert.GetExpirationDateString()
                            }
                        }
                    }
                    
                }
                
            }
        }
        else {
            $Cert = Get-ChildItem $Path | Where-Object { $_.Subject -like "*Lightspeed*" }
            if ($IncludeDates) {
                
                $Cert | Select-Object @ObjectParams
            }
            else {
                $Cert
            }
        }    
    }      
}   