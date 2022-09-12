<##Requires -modules "ActiveDirectory"
#>
function Get-DinoPass {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Simple')]
        [switch]
        $Simple,
        [Parameter(ParameterSetName = 'Strong')]
        [switch]
        $Strong
    )
    begin {
        $URI = 'http://www.dinopass.com/password/'
    }
    process {
        if ($Simple) {
            $Results = 'simple'
            Invoke-RestMethod -Method Get -Uri ($URI + $Results)
        }
        if ($Strong) {
            $Results = 'strong'
            Invoke-RestMethod -Method Get -Uri ($URI + $Results)
        }

    }
    
}

function Reset-StudentPass {
    param (
        
    )
    begin {
        $Password = "newstudent"
    }
    process {


    }
}

function Get-ADAccounts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter path to CSV file")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            try {
                Get-Item -Path $_ -ErrorAction Stop
            }
            catch [System.Management.Automation.ItemNotFoundException] {
                Write-Error -Message "Invalid file path, file does not exist"
                break
            }
            if ($_ -notmatch "(\.csv)$") {
                Write-Error -Message "File is not a CSV"
                break
            }
            else {
                return $true
            }
        })]
        [string]
        $Path
    )
    begin {
        <# $ADResults = [PSCustomObject]@{
            LastName  = $Results.Surname
            FirstName = $Results.GivenName
            Username  = $Results.SamAccountName         
        } #>
        $ADResults = @()
        $SearchBase = "OU=Azalea Middle School,OU=Students,DC=BHSD,DC=local"
    }
    process {
        $CSV = Import-Csv $Path | Sort-Object -Property Last_Name -Unique
        foreach ($students in $CSV) {
            $LastName = $students.'Last_Name'
            $FirstName = $students.'First_Name'
            
            $Results = Get-ADUser -Filter { Surname -eq $LastName -and GivenName -eq $FirstName } -SearchBase $SearchBase

            $ADResults += [PSCustomObject]@{
                LastName  = $Results.Surname
                FirstName = $Results.GivenName
                Username  = $Results.SamAccountName
                DN        = $Results.DistinguishedName
            }
        }
    }
    end {
        $ADResults
    }   
}

Get-Students -Path "C:\users\robertb\Desktop\Hall_Students.csv"