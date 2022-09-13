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
        [string[]]
        $ComputerName,
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $False,
            Position = 1)]
        [string]
        $Path = "Cert:\LocalMachine\Root\",
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $False)]
        [switch]
        $IncludeDates,
        [Parameter(Mandatory = $False,
            ValueFromPipeline = $False)]
        [switch]
        $Expired    
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
                $ComputerArray = [PSCustomObject]@{
                    Computer = $PSItem   
                }
                if (Test-Connection -TargetName $PSItem -Quiet) {
                    $ComputerArray | Add-Member -MemberType 'NoteProperty' -Name "Status" -Value "ONLINE"
                    
                    $RemoteParams = @{
                        ComputerName = $PSItem
                        ScriptBlock  = { Get-ChildItem $args | Where-Object { $_.Subject -like "*Lightspeed*" } }
                        ArgumentList = "Cert:\LocalMachine\Root\"
                    }
                    
                    $GetCert = Invoke-Command @RemoteParams
                    if ($null -eq $GetCert) {
                        $NoLSSVParams = @{
                            MemberType = 'NoteProperty'
                            Name       = "Lightspeed Status"
                            Value      = "NOT INSTALLED"
                        }
                        $ComputerArray | Add-Member @NoLSSVParams
                    }
                    else {
                        $LSSVParams = @{
                            MemberType = 'NoteProperty'
                            Name       = "Lightspeed Status"
                            Value      = "INSTALLED"
                        }
                        $ComputerArray | Add-Member @LSSVParams
                        
                        <# foreach ($Cert in $GetCert) {
                            $IssuerParams += @{
                                MemberType = 'NoteProperty'
                                Name       = "Issuer"
                                Value      = $Cert.Issuer
                                Force      = $True
                            }
                            $ComputerArray | Add-Member @IssuerParams
                            
                            $BeginDateParams += @{
                                MemberType = 'NoteProperty'
                                Name       = "Begins"
                                Value      = $Cert.GetEffectiveDateString()
                                Force      = $True
                            }
                            $ComputerArray | Add-Member @BeginDateParams
                            
                            $ExpiredDateParams += @{
                                MemberType = 'NoteProperty'
                                Name       = "Expires"
                                Value      = $Cert.GetExpirationDateString()
                                Force      = $True
                            }
                            $ComputerArray | Add-Member @ExpiredDateParams  
                        } #>
                        $GetCert | ForEach-Object {
                            $IssuerParams += @{
                                MemberType = 'NoteProperty'
                                Name       = "Issuer"
                                Value      = $Cert.Issuer
                                Force      = $True
                            }
                            $ComputerArray | Add-Member @IssuerParams
                            
                            $BeginDateParams += @{
                                MemberType = 'NoteProperty'
                                Name       = "Begins"
                                Value      = $Cert.GetEffectiveDateString()
                                Force      = $True
                            }
                            $ComputerArray | Add-Member @BeginDateParams
                            
                            $ExpiredDateParams += @{
                                MemberType = 'NoteProperty'
                                Name       = "Expires"
                                Value      = $Cert.GetExpirationDateString()
                                Force      = $True
                            }
                            $ComputerArray | Add-Member @ExpiredDateParams  

                        }


                    }
                    
                }
                else {
                    $ComputerArray | Add-Member -MemberType 'NoteProperty' -Name "Status" -Value "OFFLINE"
                }    
            }
        }
        else {
            $Cert = Get-ChildItem $Path | Where-Object { $_.Subject -like "*Lightspeed*" }
            if ($IncludeDates) {
                
                $Cert | Select-Object @ObjectParams
            }
        }    
    }
    end {
        $Results
    }      
} 

Get-RelayCert -ComputerName "MorinPC01" -IncludeDates