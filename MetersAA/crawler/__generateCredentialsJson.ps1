# create a dummy credentials.json file it one is not there

if(-Not (Test-Path "$PSScriptRoot\__credentials.json")) {

        $strTemplateConfig = @"
[{
	"username": "domain.local\\username01",
	"password": "superSAFEpassword!"
},
{
	"username": "administrator",
	"password": "superSAFEpassword?"
}]
"@
 
    $strTemplateConfig > "$PSScriptRoot\__credentials.json" 
    
    echo "Generated file: " (ls "$PSScriptRoot\__credentials.json" | Select-Object -expand FullName)
 
}