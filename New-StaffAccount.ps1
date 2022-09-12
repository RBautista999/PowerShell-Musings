<# #requires -Module "ActiveDirectory" #>

function New-StaffAccount {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $LastName,
        [Parameter()]
        [string]
        $FirstName,
        [Parameter()]
        [ValidateSet(
            "Azalea Middle School", "Kalmiopsis Elementary School", "Brookings-Harbor High School")]
        [string]
        $Location,
        [Parameter()]
        [ValidateSet(
            "Classified", "Confidential", "Licensed"
        )]
        [string]
        $Classification
    )
    begin {
        $StaffArray = [PSCustomObject]@{
            Lastname  = $LastName
            FirstName = $FirstName
            Worksite  = $Location
            JobType   = $Classification
        }
    }
    process {
        $StaffArray | Foreach-Object -ThrottleLimit 10 -Parallel {
            Get-ADUser -Filter { Surname -eq $_.LastName -and GivenName -eq $_.FirstName }
        }

    }
    
}
$Params = @{
    LastName       = "Moesby"
    FirstName      = "Ted"
    Location       = "Brookings-Harbor High School"
    Classification = "Classified"
}

New-StaffAccount @Params