$GAM = "C:\GAMADV-XTD3\gam.exe"
$GAMArguments = 'redirect csv ".\Chromebooks\Chrome Devices.csv" print cros fields deviceid,annotatedassetid,ethernetmacaddress,macaddress,model,serialnumber,autoupdateexpiration,status'
$CSVPath = "$env:USERPROFILE\Desktop"
Set-Location -Path $CSVPath
$PathCheck = Test-Path -Path ".\Chromebooks"

if ($PathCheck -eq $false) {
    Write-Verbose "The 'Chromebooks' directory was not found on the user's Desktop"
    try {
        Write-Verbose "Creating 'Chromebooks' folder under current path"
        New-Item -Path . -Name "Chromebooks" -ItemType "Directory"
    }
    catch {
        
    }
}
else {
    Write-Verbose "The 'Chromebooks' directory is present in the user's Desktop, proceeding with crOS export from GAM"
    try {
        Start-Process -FilePath $GAM -ArgumentList $GAMArguments -NoNewWindow -Wait
    }
    catch {
        Write-Error "System cannot find the executable specified"
    }
}

# Start-Process -FilePath $GAM -ArgumentList $GAMArguments -NoNewWindow -Wait


$ChromeDevices = Import-Csv '.\Chromebooks\Chrome Devices.csv'

$Upload = @()

foreach ($Device in $ChromeDevices) {
    $DAPI = $Device.'deviceId'
    $AssetID = $Device.'annotatedAssetId'
    $WiredMAC = $Device.'ethernetMacAddress'
    $WirelessMAC = $Device.'macAddress'
    $BaseModel = $Device.'model'
    $Serial = $Device.'serialNumber'
    $Update = $Device.'autoUpdateExpiration'
    $Status = $Device.'status'

    $FormatWiredMAC = $WiredMAC -replace '..(?!$)', '$&:'
    $FormatWirelessMAC = $WirelessMAC -replace '..(?!$)', '$&:'

    switch -wildcard ($BaseModel) {
        "*Lenovo*" { $Manufacturer = 'Lenovo' }
        "*100e 2nd Gen AMD*" { $Manufacturer = 'Lenovo' }
        "*100e 2nd Gen AMD*" { $Category = 'Chromebook' }
        "*HP*" { $Manufacturer = 'HP' }
        "*Dell*" { $Manufacturer = 'Dell' }
        "*Samsung*" { $Manufacturer = 'Samsung' }
        "*Acer*" { $Manufacturer = 'Acer' }
        "*Chromebox*" { $Category = 'Chromebox' }
        "*Chromebook*" { $Category = 'Chromebook' }   
    }
    
    $Upload += [PSCustomObject]@{
        "Manufacturer"           = $Manufacturer
        "Model Name"             = $BaseModel
        "Category"               = $Category
        "Asset Tag"              = $AssetID
        "Auto Update Expiration" = $Update
        "Directory API ID"       = $DAPI
        "Serial Number"          = $Serial
        "Chrome Status"          = $Status
        "Wired MAC Address"      = $FormatWiredMAC
        "WiFi MAC Address"       = $FormatWirelessMAC

    }
    Write-Progress -Activity "Formatting Chrome Device Inventory for Snipe-It Importing" -Status "Chrome Device #$($Upload.Count) of $($ChromeDevices.Count)" -PercentComplete (($Upload.Count / $ChromeDevices.Count * 100))

    $Upload | Export-Csv -NoTypeInformation -Path '.\Chromebooks\SnipeChrome.csv'

}

