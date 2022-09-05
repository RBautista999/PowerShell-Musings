function Get-RelayVersion {
   
    [CmdletBinding()]
    [OutputType('Microsoft.Win32.RegistryKey')]
    param (
            
    )
        
    begin {
        $InstalledSoftware = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $Relay = $InstalledSoftware | Where-Object { $PSItem.GetValue("Publisher") -like "*Lightspeed*" }
         
    }
        
    process {
        if ( $Relay.GetValue("DisplayVersion") -gt "1.11.0"){
            Write-Output "Running unsupported version of Smart Agent"
        }
        else {
            Write-Output "Running supported version of Smart Agent"
        }
            
    }
        
    end {
            
    }    

}