param(    
    [Parameter(Mandatory)]
    [Alias("config")]
    [string]$pathToConfig = "$PSScriptRoot\config.json"
)

if(-Not (Test-Path $pathToConfig)) {
    Write-Host "List [$pathToConfig] not found." -ForegroundColor Red
    exit
}

# parse the variables from a 'config.json' file in the same directory
# Source -> https://stackoverflow.com/questions/24142436/powershell-parsing-a-properties-file-that-contains-colons
 
######################################
 
# Reading file as a single string:
$sRawString = Get-Content $pathToConfig | Out-String
 
# The following line of code makes no sense at first glance 
# but it's only because the first '\\' is a regex pattern and the second isn't. )
$sStringToConvert = $sRawString -replace '\\', '\\'
 
# And now conversion works.
$htProperties = ConvertFrom-Json $sStringToConvert

##########################################################

# script to insert data into normalized tables

$powershellDatabase = $htProperties.powershellSqlDatabase
$djangoDatabase = $htProperties.djangoSqlDatabase

# this will be the database we are mirroring everything to

$attachDestinationDatabaseQuery = @"
    ATTACH "$($djangoDatabase)" AS 'destination';
"@


##########################################################

foreach($mapping in $htProperties.mappings) 
{
    $djangoTable = $mapping.djangoSqlTable

    $powershellTable = $mapping.powershellSqlTable
    $powershellColumns = ($mapping.powershellToDjangoColumnMappings | Get-Member -MemberType NoteProperty).Name
    
    
    # 1
    #################

    $str_powershellColumns = ""

    # 1.1 - From config.json, write SOURCE columns to STRING
    if( $powershellColumns -isnot [String] ) {
        for($i=0; $i -lt $powershellColumns.Length; $i++) {
            $str_powershellColumns += '"{0}"' -f $powershellColumns[$i]

            if($i -lt $powershellColumns.Length-1) {
                $str_powershellColumns += ","
            }

        }
    } else {
        $str_powershellColumns = '"{0}"' -f $powershellColumns
    }

    Write-Host $str_powershellColumns -ForegroundColor Red
    
    # 1.2 - use SOURCE STRING to query SOURCE for DATA
    $sourceQuery = "SELECT {0} FROM 'main'.{1}" -f ($str_powershellColumns,$powershellTable)

    Write-Host $sourceQuery -ForegroundColor Red
    
    # 2 
    #################

    $str_djangoColumns = ""

    # 2.1 - From config.json, write DESTINATION columns to STRING
    if( $powershellColumns -isnot [String] ) {
        for($i=0; $i -lt $powershellColumns.Length; $i++) {
            $str_djangoColumns += '"{0}"' -f $mapping.powershellToDjangoColumnMappings.($powershellColumns[$i])

            if($i -lt $powershellColumns.Length-1) {
                $str_djangoColumns += ","
            }

        }
    } else {
        $str_djangoColumns = '"{0}"' -f $mapping.powershellToDjangoColumnMappings.$powershellColumns
    }

    Write-Host $str_djangoColumns -ForegroundColor Yellow

    $destinationQuery = "INSERT OR IGNORE INTO 'destination'.{0}({1})" -f ($djangoTable,$str_djangoColumns)

    Write-Host $destinationQuery -ForegroundColor Yellow
    
    # 2.2 - aggregate query strings into FINAL STRING to query insert into DESTINATION
    
    $finalQuery = "$attachDestinationDatabaseQuery $destinationQuery $sourceQuery;"

    Write-Host $finalQuery -ForegroundColor Cyan

    Invoke-SqliteQuery -Query $finalQuery -Database $powershellDatabase

} # END foreach(mapping)
