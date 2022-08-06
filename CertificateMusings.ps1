
$Computers = (Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(operatingSystem=Windows 10*))").Name
$result = @()
$Result = foreach ($Computer in $Computers) {
    $ErrorActionPreference = "SilentlyContinue"
    if (Test-Connection -TargetName $Computer -Quiet) {
        Write-Host "Connection to $($Computer) succesful" -ForegroundColor Green 
        $GetCert = Invoke-Command -ComputerName $Computer { Get-ChildItem Cert:\LocalMachine\Root\ | Where-Object { $_.Subject -like "*Lightspeed*" } }
        if ($null -eq $GetCert) {
            Write-Host "!!!$($Computer) doesn't have Lightspeed Relay Smart Agent installed!!!" -ForegroundColor Red
        }
        else {
            Write-Host "--->We found a Lightspeed cert, adding result(s) to array<---" -ForegroundColor Cyan
            foreach ($Cert in $GetCert) {
                [PSCustomObject]@{
                    'Computer'    = $Computer;
                    'Certificate' = $Cert.Issuer;
                    'Begins'      = $Cert.GetEffectiveDateString()
                    'Expires'     = $Cert.GetExpirationDateString();
                }
            }
        }
        
    }
    else {
        Write-Warning -Message "Unable to connect to $($Computer)"
    }
    

}
$Result | Sort-Object Expires | Export-CSV -NoTypeInformation 'LightspeedCerts.csv'