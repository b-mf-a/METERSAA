# https://www.powershellgallery.com/packages/PSSQLite/1.0/Content/Invoke-SqliteQuery.ps1
# below functions hinge on above module. Try to install if not found.
try {
    # if this command is available, then we assume the PSSQLite module to be installed
    Get-Command Invoke-SqliteQuery -ErrorAction Stop > $null
} catch {
    Write-Warning "PSSQLite Module not found. Attempting to install..."
    Install-Module -Name "PSSQLite" -Force
}

function Initialize-MAASqliteDatabase {

    param(
        [Parameter(Mandatory)]
        [Alias("database")]
        [string]$pathToSqliteDatabase
    )

    if( -Not (Test-Path $pathToSqliteDatabase -PathType Leaf) ) {

$query = @"
        CREATE TABLE 'scan_results' (
	        'result_id'	INTEGER,
	        'result_computername_id'	INTEGER,
	        'result_filedesktoppresent'	INTEGER,
	        'result_filecurrentpresent'	INTEGER,
	        'result_subnet_id'	INTEGER,
	        'result_deviceid_id'	INTEGER,
	        'result_datetime'	TEXT,
	        PRIMARY KEY(result_id)
        );

        CREATE TABLE 'core_computernames' (
            'computername_id'	INTEGER,
            'computername_name'	TEXT UNIQUE,
            PRIMARY KEY(computername_id)
        );

        CREATE TABLE 'core_subnets' (
            'subnet_id'	INTEGER,
            'subnet_address'	TEXT UNIQUE,
            PRIMARY KEY(subnet_id)
        );

        CREATE TABLE 'core_deviceids' (
	        'deviceid_id'	INTEGER,
	        'deviceid_ori'	TEXT,
	        'deviceid_termid'	TEXT NOT NULL UNIQUE,
	        PRIMARY KEY(deviceid_id),
	        UNIQUE(deviceid_ori,deviceid_termid)
        )
"@

        Invoke-SqliteQuery -Query $query -Database $pathToSqliteDatabase
    
    }

$query = @"
    CREATE TABLE if not exists 'temp_scan_results' (
	    'computername'	TEXT,
	    'filedesktoppresent'	INTEGER,
	    'filecurrentpresent'	INTEGER,
	    'ori'	TEXT,
	    'termid'	TEXT,
	    'subnet'	TEXT,
	    'datetime'	TEXT
    );
"@

    Invoke-SqliteQuery -Query $query -Database $pathToSqliteDatabase

    echo "Initialized Sqlite Database [$pathToSqliteDatabase]"

    return

} # END FXN Initialize-MAASqliteDatabase



function Normalize-MAASqliteDatabase {

    param(
        [Parameter(Mandatory)]
        [Alias("database")]
        [string]$pathToSqliteDatabase
    )

    if( -Not (Test-Path $pathToSqliteDatabase -PathType Leaf) ) {
        echo "Cannot Normalize Data in Sqlite Database [$pathTpSqliteDatabase]: Database Does Not Exist."
        return
    }

$query = @"
    INSERT OR IGNORE INTO core_computernames(computername_name)
    SELECT computername FROM temp_scan_results;

    INSERT OR IGNORE INTO core_subnets(subnet_address)
    SELECT subnet FROM temp_scan_results;

    INSERT OR IGNORE INTO core_deviceids(deviceid_ori,deviceid_termid)
    SELECT ori,termid FROM temp_scan_results;

    INSERT INTO scan_results(result_computername_id,result_filedesktoppresent,result_filecurrentpresent,result_subnet_id,result_deviceid_id,result_datetime)
    SELECT c.computername_id,t.filedesktoppresent,t.filecurrentpresent,s.subnet_id,d.deviceid_id,t.datetime FROM core_computernames c
    INNER JOIN temp_scan_results t ON c.computername_name = t.computername
    LEFT JOIN core_deviceids d ON d.deviceid_termid = t.termid
    LEFT JOIN core_subnets s ON s.subnet_address = t.subnet;

    DROP TABLE IF EXISTS temp_scan_results;

    VACUUM;
"@
    Invoke-SqliteQuery -Query $query -Database $pathToSqliteDatabase

    echo "Normalized Data in Sqlite Database [$pathToSqliteDatabase]"

    return
    
} # END FXN Normalize-MAASqliteDatabase



function Add-ResultToSqliteDatabase {
    param(
        [Parameter(Mandatory)]
        [Alias("database")]
        [string]$pathToSqliteDatabase,

        [Parameter(Mandatory)]
        [Alias("result")]
        [Object[]]$resultObject
    )

$query = @"
    INSERT INTO temp_scan_results (
        computername, 
        filedesktoppresent, 
        filecurrentpresent, 
        ori, 
        termid, 
        subnet, 
        datetime
    ) VALUES ('{0}','{1}','{2}','{3}','{4}','{5}','{6}')
"@ -f  (
            $resultObject.computername,
            $resultObject.filedesktoppresent,
            $resultObject.filecurrentpresent,
            $resultObject.ori,
            $resultObject.termid,
            $resultObject.subnet,
            $resultObject.datetime
        )     

    Invoke-SqliteQuery -DataSource $pathToSQLiteDB -Query $query

    return

} # END FXN Add-ResultToSqliteDatabase

function Find-ORIAndTermID {
    param(
        [Parameter(Mandatory)]
        [Alias("computer")]
        [string]$computerNameOrIp,
    
        [Parameter(Mandatory)]
        [string]$subnet,

        [Parameter(Mandatory=$false)]
        [Alias("state")]
        [string]$stateTwoLetterAbbrviation='MD'
    
    )

    # create a PSCustomObject with intent to return

    $myObject = [PSCustomObject]@{
        computername = $computerNameOrIp
        filedesktoppresent = $false
        filecurrentpresent = $false
        ori = $null
        termid = $null
        subnet = $subnet
        datetime = $null
        success = $null
        state = $stateTwoLetterAbbrviation

    }

    $matchORI = $null
    $matchTermId = $null

    #$pathToPrimarySource = "\\$computerNameOrIp\c$\Omnixx\OMNIXX\desktop.log" 
    #$pathToSecondarySource = "\\$computerNameOrIp\c$\Omnixx\OMNIXX\OmnixxForce\LOGS\current.idx"

    # new location when using METERS 7 (not absolutely sure) [07 08 2022 1322]

    $pathToPrimarySource = "\\$computerNameOrIp\c$\Omnixx7\OMNIXX\desktop.log"
    $pathToSecondarySource = "\\$computerNameOrIp\c$\Omnixx7\OMNIXX\OmnixxForce\LOGS\current.idx"

    try {

        $myObject.filedesktoppresent = $isPrimarySourcePresent = Test-Path $pathToPrimarySource -PathType Leaf -ErrorAction Stop
        $myObject.filecurrentpresent = $isSecondarySourcePresent = Test-Path $pathToSecondarySource -PathType Leaf -ErrorAction Stop

        # primary source

        if ( Test-Path $pathToPrimarySource -PathType Leaf ) {

            # need to do this to make file a workable object
            $strContents = Get-ChildItem $pathToPrimarySource

            # ORI (ex. MD0#####5)
            # NOTE: if a METERS/NCIC query has never been executed, you will not find the device specific ORI, only the organization's general ORI
            $matchORI = Select-String 'ORI="(\w{9})"' -InputObject $strContents
        
            try { $myObject.ori = $matchORI = $matchORI.Matches.Groups[1].Value } catch { Write-Warning "$computerNameOrIp | PSource | No ORI match with value" }

            # Term ID (ex. W###)
            $matchTermId = Select-String 'DEV ID="(\w{4})"' -InputObject $strContents
            if (-Not $matchTermId) { $matchTermId = Select-String 'SDV DEV="(\w{4})"' -InputObject $strContents }
            if (-Not $matchTermId) { $matchTermId = Select-String 'SDV VAL="(\w{4})"' -InputObject $strContents }
            if (-Not $matchTermId) { $matchTermId = Select-String 'sAdr is (\w{4})' -InputObject $strContents }

            try { $matchTermId = $myObject.termid = $matchTermId.Matches.Groups[1].Value } catch { Write-Warning "$computerNameOrIp | PSource | No TermID match with value" }
        
        }

        # secondary source (if primary doesn't yield results)

        if(
            ( (-Not $matchORI) -or (-Not $matchTermId) ) -and
            ($isSecondarySourcePresent) ) {
        
            $strContents = Get-ChildItem $pathToSecondarySource
            
            $match = Select-String "($($stateTwoLetterAbbrviation)\w{7})[\x00-\x7F][\x00-\x7F](\w{4})" -InputObject $strContents
            
            if($match) {
                if (-Not $matchORI) { $myObject.ori = $matchORI = $match.Matches[-1].Groups[1].Value }
                if (-Not $matchTermId) { $myObject.termid = $matchTermId = $match.Matches[-1].Groups[2].Value }
            }
        }

        $myObject.datetime = $(Get-Date -Format 'yyyyMMdd-HHmm-ss')
        $myObject.success = $true
    
        #return $myObject

    } catch {

        $myObject.success = $false
    
    }

    return $myObject

} # END FXN Find-ORIAndTermID

function Get-MAAConfig {
    param(
        [Parameter(Mandatory)]
        [Alias("config")]
        [string]$pathToConfigFile
    )

    # Reading file as a single string:
    $sRawString = Get-Content $pathToConfigFile | Out-String
 
    # The following line of code makes no sense at first glance 
    # but it's only because the first '\\' is a regex pattern and the second isn't. )
    $sStringToConvert = $sRawString -replace '\\', '\\'
 
    # And now conversion works.
    $htProperties = ConvertFrom-Json $sStringToConvert
 
    # no value in config.json can be $null
    if(
        (-Not $htProperties.'pathToNmapExecutable') ) {
        Write-Host "Config File Invalid. Variable 'pathToNmapExecutable' must be set." -ForegroundColor Red
        exit
    }
 
    return $htProperties

} # END FXN Get-MAAConfig