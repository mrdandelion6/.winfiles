# PowerShell script to symlink winfiles from ~/.winfiles/winfiles to home directory

# Configuration
$dotfilesRoot = Join-Path (Join-Path $HOME ".winfiles") "winfiles"
$ignoreFile = "ignore.txt"

# Function to check if a path matches any pattern in the ignore list
function Test-Ignored {
    param (
        [string]$RelPath,
        [string[]]$IgnorePatterns
    )
    $RelPath = $RelPath.Replace('/', '\')

    foreach ($pattern in $IgnorePatterns) {
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($pattern) -or $pattern.Trim().StartsWith('#')) {
            continue
        }
        
 	$trimmedPattern = $pattern.Trim()
        
        # Simple exact match for a filename anywhere in the path
        if ($RelPath -like "*\$trimmedPattern" -or $RelPath -eq $trimmedPattern) {
            Write-Host "Ignoring: $RelPath (matched ignore pattern: $pattern)" -ForegroundColor Yellow
            return $true
        }
        
        # Match pattern with wildcards
        if ($RelPath -like $trimmedPattern) {
            Write-Host "Ignoring: $RelPath (matched wildcard pattern: $pattern)" -ForegroundColor Yellow
            return $true
        }
        
        # Check each path component individually
        $pathComponents = $RelPath -split '\\'
        foreach ($component in $pathComponents) {
            if ($component -like $trimmedPattern) {
                Write-Host "Ignoring: $RelPath (component '$component' matched pattern: $pattern)" -ForegroundColor Yellow
                return $true
            }
        }
    }
    
    return $false
}

# Ensure winfiles root exists
if (-not (Test-Path $dotfilesRoot)) {
    Write-Error "Winfiles directory not found: $dotfilesRoot"
    exit 1
}

# Read ignore patterns from file
if (Test-Path $ignoreFile) {
    $ignorePatterns = Get-Content $ignoreFile
} else {
    Write-Warning "Ignore file not found: $ignoreFile. No files will be ignored."
    $ignorePatterns = @()
}

# Find all files recursively in the winfiles directory
$winfiles = Get-ChildItem -Path $dotfilesRoot -Recurse -File -ErrorAction SilentlyContinue

foreach ($winfile in $winfiles) {
    # Get the relative path from winfiles root
    $relPath = $winfile.FullName.Substring($dotfilesRoot.Length + 1)
    
    # Check if relPath is in the ignore list
    if (Test-Ignored -RelPath $relPath -IgnorePatterns $ignorePatterns) {
        continue
    }
    
    # Determine target path in home directory
    $targetPath = Join-Path $HOME $relPath
    $targetDir = Split-Path -Parent $targetPath
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        Write-Host "Created directory: $targetDir" -ForegroundColor Cyan
    }
    
    # Remove the file if it exists
    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Force
    }
    
    # Create symbolic link directly without using Invoke-Expression
    try {
        gsudo New-Item -ItemType SymbolicLink -Path $targetPath -Target $winfile.FullName -Force | Out-Null
        Write-Host "Linked: $($winfile.FullName) -> $targetPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating symbolic link for $targetPath. Do you have admin rights?" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

Write-Host "`nWinfiles installation complete!" -ForegroundColor Green
