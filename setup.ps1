$ErrorActionPreference = "Stop"

$RequiredMajor = 3
$RequiredMinor = 11
$VenvDir = ".venv"
$KernelName = "computer-vision-project"
$KernelDisplayName = "Python 3.11 (Computer Vision Project)"

# Always work from the directory where this script lives.
Set-Location $PSScriptRoot

Write-Host "==> Checking for Python $RequiredMajor.$RequiredMinor..."

$PythonCommand = $null
$PythonArguments = @()

# Prefer the Windows Python launcher because it can select an exact version.
if (Get-Command py -ErrorAction SilentlyContinue) {
    try {
        & py -3.11 -c "import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 11) else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $PythonCommand = "py"
            $PythonArguments = @("-3.11")
        }
    }
    catch {}
}

# Fallback to python if the launcher is not available.
if (-not $PythonCommand -and (Get-Command python -ErrorAction SilentlyContinue)) {
    try {
        & python -c "import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 11) else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $PythonCommand = "python"
            $PythonArguments = @()
        }
    }
    catch {}
}

if (-not $PythonCommand) {
    Write-Host "ERROR: Python $RequiredMajor.$RequiredMinor is required but was not found." -ForegroundColor Red
    Write-Host "Install Python $RequiredMajor.$RequiredMinor and run this script again."
    exit 1
}

$PythonVersion = & $PythonCommand @PythonArguments --version
Write-Host "    Found: $PythonVersion"

if (-not (Test-Path "requirements.txt")) {
    Write-Host "ERROR: requirements.txt was not found in $PSScriptRoot" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $VenvDir)) {
    Write-Host "==> Creating virtual environment in $VenvDir..."
    & $PythonCommand @PythonArguments -m venv $VenvDir
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
else {
    Write-Host "==> Virtual environment already exists: $VenvDir"
}

$VenvPython = Join-Path $VenvDir "Scripts\python.exe"

if (-not (Test-Path $VenvPython)) {
    Write-Host "ERROR: The virtual environment is invalid or incomplete." -ForegroundColor Red
    Write-Host "Delete '$VenvDir' and run this script again."
    exit 1
}

Write-Host "==> Upgrading pip..."
& $VenvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> Installing dependencies from requirements.txt..."
& $VenvPython -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> Checking installed dependencies..."
& $VenvPython -m pip check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> Registering Jupyter kernel..."
& $VenvPython -m ipykernel install --user --name $KernelName --display-name $KernelDisplayName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Setup completed successfully." -ForegroundColor Green
Write-Host "Activate the environment with:"
Write-Host "  .\.venv\Scripts\Activate.ps1"
Write-Host ""
Write-Host "Then start Jupyter with:"
Write-Host "  jupyter notebook"
