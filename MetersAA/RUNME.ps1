Write-Host "### 1. Installing + Configuring Django Requirements ###" -ForegroundColor Cyan
. "$PSScriptRoot\__0_python-venv.ps1"

Write-Host "### 2. Installing IIS web server ###" -ForegroundColor Cyan
. "$PSScriptRoot\__1_iis.ps1"

Write-Host "### 3. Setting IIS configuration ###" -ForegroundColor Cyan

# Proceeding portion hinges on cmdlet 'Enable-IISSharedConfig'. Quit if it doesn't exist. 
try {
    Get-Command Enable-IISSharedConfig -ErrorAction Stop > $null
} catch {
    Write-Host "Cmdlet 'Enable-IISSharedConfig' is missing. Please install then try again." -ForegroundColor Red
    exit
}

Enable-IISSharedConfig -PhysicalPath  "$PSScriptRoot\iis-config\" -DontCopyRemoteKeys

Write-Host "### 4. Generating dummy /crawler/__credentials.json ###" -ForegroundColor Cyan
. "$PSScriptRoot\crawler\__generateCredentialsJson.ps1"

Write-Host "All Done." -ForegroundColor Green