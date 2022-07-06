# this can be 1st

if (-Not (Test-Path "$PSScriptRoot\frontend\" -PathType Container) ) {
    Write-Host "Did not find path to MetersAA front end [$PSScriptRoot\frontend\]" -ForegroundColor Red
    return
}

python.exe -m venv frontend

cd "$PSScriptRoot\frontend\"

. "$PSScriptRoot\frontend\Scripts\Activate.ps1"

python.exe -m pip install --upgrade pip

pip install -r "$PSScriptRoot\frontend\requirements.txt"

# initialize the SQLite database Django app

python.exe "$PSScriptRoot\frontend\manage.py" makemigrations
python.exe "$PSScriptRoot\frontend\manage.py" migrate

# collect static files

python.exe "$PSScriptRoot\frontend\manage.py" collectstatic

# create an admin user

python.exe "$PSScriptRoot\frontend\manage.py" createsuperuser
