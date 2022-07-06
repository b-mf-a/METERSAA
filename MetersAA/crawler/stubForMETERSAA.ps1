$masterList = Invoke-RestMethod -Uri "http://localhost/masterlist/subnets/"

$masterList.fields.subnet_address | foreach { . "$PSScriptRoot\METERSAA.ps1" $_ } 