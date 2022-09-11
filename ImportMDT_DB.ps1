Import-Module -Name MDTDatabase

$SQLConnection = @{
    sqlServer = "BHSDMDT02"
    instance  = "SQLEXPRESS"
    database  = "Deployment"
    
}

Connect-MDTDatabase @SQLConnection

$HSLab = Import-Csv "C:\Users\robertb\Desktop\BHHSGraphics.csv"

foreach ($PC in $HSLab) {
    
    $Settings = @{
        OSInstall       = 'YES'
        OSDComputerName = $PC.Name
    }

    New-MDTComputer -serialNumber $PC.Serial -description $PC.Name -settings $Settings
    Start-Sleep -Seconds 2

    
    $ID = (Get-MDTComputer -serialNumber $PC.Serial).ID
    Set-MDTComputerRole -id $ID -roles $PC.Roles

}
