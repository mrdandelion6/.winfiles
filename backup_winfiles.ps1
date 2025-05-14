# PowerShell script to backup existing files in home directory that match the structure in winfiles
# before they are replaced with symlinks

# Configuration
$dotfilesRoot = Join-Path (Join-Path $HOME ".winfiles") "winfiles"
$backupPrefix = ".winfiles_bkp_"
$ignoreFile = "ignore.txt"

# Function to check if a path matches any pattern in the ignore list (same as in install script)
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

# Find the next available backup directory number
$backupNumber = 1
while (Test-Path (Join-Path $HOME ($backupPrefix + $backupNumber))) {
    $backupNumber++
}
$backupDir = Join-Path $HOME ($backupPrefix + $backupNumber)

# Create the backup directory
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Write-Host "Created backup directory: $backupDir" -ForegroundColor Cyan

# Track if we've made any backups
$backedUpCount = 0

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

    # If the file exists and is not a symlink, back it up
    if (Test-Path $targetPath) {
        $item = Get-Item $targetPath -Force

        # Skip if it's already a symlink (likely from a previous install)
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "Skipping already symlinked file: $targetPath" -ForegroundColor Gray
            continue
        }

        # Create the directory structure in the backup
        $backupFilePath = Join-Path $backupDir $relPath
        $backupFileDir = Split-Path -Parent $backupFilePath

        if (-not (Test-Path $backupFileDir)) {
            New-Item -Path $backupFileDir -ItemType Directory -Force | Out-Null
        }

        # Copy the file to backup
        try {
            Copy-Item -Path $targetPath -Destination $backupFilePath -Force
            $backedUpCount++
            Write-Host "Backed up: $targetPath -> $backupFilePath" -ForegroundColor Green
        }
        catch {
            Write-Host "Error backing up $targetPath" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }
}

# Report results
if ($backedUpCount -eq 0) {
    Write-Host "`nNo files needed to be backed up." -ForegroundColor Yellow
    # Remove empty backup directory if we didn't back up anything
    Remove-Item -Path $backupDir -Force
    Write-Host "Removed empty backup directory: $backupDir" -ForegroundColor Gray
} else {
    Write-Host "`nBackup complete! $backedUpCount files were backed up to $backupDir" -ForegroundColor Green
}
