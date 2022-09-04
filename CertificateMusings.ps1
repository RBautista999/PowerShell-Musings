$ErrorActionPreference = "Stop"
#requires -version 7.2

if (!(Get-Module -Name ActiveDirectory)) {
    Write-Output "Importing Active Directory Module"
    Import-Module ActiveDirectory
}

$Computers = (Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(operatingSystem=Windows 10*))").DNSHostName

$Results = $Computers | Foreach-Object -ThrottleLimit 10 -Parallel {
    if (Test-Connection -TargetName $PSItem -Quiet) {
        Write-Host "Connection to $($PSItem) successful" -ForegroundColor Green 
        $Parameters = @{
            ComputerName = $PSItem
            ScriptBlock  = { Get-ChildItem $args | Where-Object { $_.Subject -like "*Lightspeed*" } }
            ArgumentList = "Cert:\LocalMachine\Root\"
        }
        
        $GetCert = Invoke-Command @Parameters
        if ($null -eq $GetCert) {
            Write-Warning "$($PSItem) doesn't have Lightspeed Relay Smart Agent installed"
        }
        else {
            Write-Host "--->We found a Lightspeed cert, adding result(s) to array<---" -ForegroundColor Cyan
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
    else {
        Write-Warning -Message "Unable to connect to $($PSItem)"
    }
}

$Results | Sort-Object { $PSItem.Expires -as [datetime] }  | Export-CSV -NoTypeInformation 'LightspeedCerts.csv'