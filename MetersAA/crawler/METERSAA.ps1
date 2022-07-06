# subnet (e.g. 172.x.x.*) to perform search on

param(
        [Parameter(Mandatory)]
        [string]$subnet
)

# verify script being run with Powershell 7 or greater

if( $host.Version.Major -lt 7 ){
    Write-Error "Script must be run with Powershell version 7 or greater."
    return
}

# import helper functions

. "$PSScriptRoot\MAAHelperFunctions.ps1"

#----------------------------------------

# verify the 'config.json' file exists in the same directory as this script

if(-Not (Test-Path "$PSScriptRoot\config.json")) {
    echo ""
    Write-Host "Config File Not Found." -ForegroundColor Red
    echo ""
    Write-Host "Do you want to generate a templated config file [y/n]? " -ForegroundColor Yellow -NoNewline
    $boolGenerateConfigFile = Read-Host
 
    if ( $boolGenerateConfigFile -match "[yY]" ) {
 
        $strTemplateConfig = @"
{
  "pathToNmapExecutable": "C:\Program Files (x86)\Nmap\nmap.exe",
  "nmapResultFilterRegex": "",
  "stateTwoLetterAbbreviation": "MD"
} 
"@
 
        $strTemplateConfig > "$PSScriptRoot\config.json" 
        echo "Generated file: " (ls "$PSScriptRoot\config.json" | Select-Object -expand FullName)
    } else {
        Write-Host "No config file generated.`nPlease place a 'config.json' file in '$PSScriptRoot' and then re-run this script." -ForegroundColor Red
        exit
    }
 
}

#----------------------------------------

$configVariables = Get-MAAConfig "$PSScriptRoot\config.json"
$pathToNmapExecutable = $configVariables.'pathToNmapExecutable'

#Write-Host $pathToNmapExecutable -ForegroundColor Green
#Write-Host $configVariables.'nmapResultFilterRegex' -ForegroundColor Green
#Write-Host $configVariables.'stateTwoLetterAbbreviation' -ForegroundColor Green

# verify the path to Nmap exe

if(-Not (Test-Path $pathToNmapExecutable )) {
    echo ""
    Write-Host "Path to NMap.exe ($pathToNmapExecutable) is invalid" -ForegroundColor Red
    exit
 
}

# unmaps all drives letters, as these may be used by script

net use * /delete /y

Enum DriveLetters

{

M
N
O
P
Q
R
S
T
U
V
W
X
Y
Z

}

$writeLocation = "$PSScriptRoot\logs"
if (-Not (Test-Path $writeLocation -PathType Container) ) { mkdir $writeLocation }

$pathToSQLiteDB = "$writeLocation\results314.SQLite"
$pathToUnknownCredentialClients = "$writeLocation\credentials-unknown.txt"

$jsonOtherCredentials = "$PSScriptRoot\credentials.json"

$arrlstDifferentCredentialClients = New-Object System.Collections.ArrayList($null)

Initialize-MAASqliteDatabase -pathToSqliteDatabase $pathToSQLiteDB

# ---------------------------------------------

function Complete-MAAResourceCleanup {

    # unmaps all drives letters that may have been used by script
    
    net use * /delete /y

    # normalize data in sqlite db
    
    Normalize-MAASqliteDatabase -pathToSqliteDatabase $pathToSQLiteDB

}

# ---------------------------------------------

################################################
#          Part 1 - Parallel Execution         #
################################################

# Get the function's definition *as a string*

$funcDef = ${function:Find-ORIAndTermID}.ToString()

# execute Nmap ping scan

$listOfDevices = & $pathToNmapExecutable -sn $subnet

# apply filter to above scan

if( $configVariables.'nmapResultFilterRegex' ) {
    
    # intent being, computername in database will be DNS name

    $listOfDevices = $listOfDevices | Select-String $configVariables.'nmapResultFilterRegex'

} else {
    
    # computername in database will be IP address
    # --- this line looks unecessarily complex because im double filtering the data so I don't have to edit the 'Matches' login the in parallel block below 
    # --- WARNING NOTE: this takes a couple seconds to execute. Best to set a RegEx in the config file
    
    $listOfDevices = ($listOfDevices | Select-String "\(([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\)").Matches.Value | Select-String "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"

}

echo $listOfDevices

$job = $listOfDevices | ForEach-Object -Parallel {
    
    # Define the function inside this thread...
    
    ${function:Find-ORIAndTermID} = $using:funcDef
    
    # ... and call it
    
    Find-ORIAndTermID -computer $_.Matches.Groups[0].Value.Trim() -subnet $using:subnet -state $using:configVariables.'stateTwoLetterAbbreviation'

} -AsJob

# set a timelimit on how long the batch of threads can run. If timelimit is exceeded, stop the job.

$sleepCounter = 0

$jobAllData = $null

# the Job needs to Complete and we need to take any data it has returned before moving on

while (($job.State -ne "Completed") -or $job.HasMoreData) {
    
    Write-Host $sleepCounter " : " $job.State

    if ($job.HasMoreData) {
        
        $jobAllData = Get-Job $job.Name | Receive-Job

        foreach($result in $jobAllData) {
            echo $result
            if($result.success) { 
                Add-ResultToSqliteDatabase -pathToSqliteDatabase $pathToSQLiteDB -resultObject $result 
            } else { 
                $arrlstDifferentCredentialClients.Add($result)
            }
        
        }
    
    }

    # 5 minutes MAX
    
    if ($sleepCounter -ge 300) {
    
        Write-Host "RUNNING TOO LONG. STOPPING..." -ForegroundColor Cyan 
        $job | Stop-Job
        break
    
    }

    Start-Sleep 5
    $sleepCounter += 5

} # END while

#
# END Part 1
#

################################################
#          Part 2 - Serial Execution           #
################################################

# this is serial because we are iterating thru mapped drive letters

if ( -Not $arrlstDifferentCredentialClients ) { 
    Complete-MAAResourceCleanup
    
    if(	[System.Convert]::ToBoolean($configVariables.boolUsingDjangoFrontEnd) ) {
        Write-Warning "Attempting to mirror data to a destination database."
        . "$PSScriptRoot\adapter\adapter.ps1" "$PSScriptRoot\adapter\config.json" 
    }
    
    return
}

if ( -Not (Test-Path -Path $jsonOtherCredentials -PathType Leaf) ) { 
    Write-Warning "Clients were found that did not work with the default credentials, but no additional credentials were provided; missing file $jsonOtherCredentials"
    Complete-MAAResourceCleanup
    
    if(	[System.Convert]::ToBoolean($configVariables.boolUsingDjangoFrontEnd) ) {
        Write-Warning "Attempting to mirror data to a destination database." 
        . "$PSScriptRoot\adapter\adapter.ps1" "$PSScriptRoot\adapter\config.json"
    }
     
    return
}

$credentials = Get-Content "$PSScriptRoot\credentials.json" | Out-String | ConvertFrom-Json

$driveLetterCount = 0

foreach ($client in $arrlstDifferentCredentialClients) {

    foreach ($credential in $credentials) {

        # Store credentials in a PSCredential object
        
        $User = $credential.username
        $PWord = ConvertTo-SecureString -String $credential.password -AsPlainText -Force
        $psCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord

        Write-Host "Trying $($client.computername) with" $credential.username -ForegroundColor Yellow

        $driveName = [DriveLetters].GetEnumName($driveLetterCount)
        if (New-PSDrive -Name $driveName -Root "\\$($client.computername)\c$" -PSProvider "FileSystem" -Credential $psCredential) {
                
            $driveLetterCount = $driveLetterCount + 1
            $jobAllData = Find-ORIAndTermID -computerNameOrIp $client.computername -subnet $client.subnet -state $configVariables.'stateTwoLetterAbbreviation'
            echo $jobAllData
            Add-ResultToSqliteDatabase -pathToSqliteDatabase $pathToSQLiteDB -resultObject $jobAllData

            break

        } else {
                
            Write-Host $credential.username "4 $($client.computername) es no bueno." -ForegroundColor Yellow
                
            # exhausted possible credentials

            if($credential -eq $credentials[-1]) {
                $client.computername >> $pathToUnknownCredentialClients
            }
        }
        
    } # END FOREACH credentials

} # END FOREACH arrlstDifferentCredentialClients

#
# END Part 2
#

Complete-MAAResourceCleanup

if(	[System.Convert]::ToBoolean($configVariables.boolUsingDjangoFrontEnd) ) {
    Write-Warning "Attempting to mirror data to a destination database." 
    . "$PSScriptRoot\adapter\adapter.ps1" "$PSScriptRoot\adapter\config.json" 
} 

echo "I printed last"