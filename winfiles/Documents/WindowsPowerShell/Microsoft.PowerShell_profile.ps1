# VERSION: 1.1.0
# Copyright (c) 2024 Faisal Shaik
# All rights reserved.
#
#
# =============================================================
# ========================== general ==========================

function als {
    Write-Host "General:" -ForegroundColor Green
    Write-Output @"
    als : list custom alias and functions
    bash_ref : reload PowerShell profile
    bash_pull : open PowerShell profile in VS Code
    ppath -v : returns the path to the given python version <v>
    hp : hide path in prompt
    spp : show path in prompt
    shortcut_path -f : return the path a shortcut (.lnk) file <f> points to
    touch : create a new file or update its timestamp
    sizeof -path : returns the size of the file or directory
"@

    Write-Host "Git:" -ForegroundColor Yellow
    Write-Output @"
    pullall : pull from all git remotes
    pushall : push to all git remotes
"@

    Write-Host "Python:" -ForegroundColor Blue
    Write-Output @"
    makenv -v : creates a virtual environment with the given python version <v> in $envdir
    actenv -n : activate the specified virtual environment with name <n>. it must be in $envdir to work
    inenv : check if currently in a virtual environment
    condarev : alias for 'conda init --reverse'
"@

    Write-Host "Java:" -ForegroundColor DarkYellow
    Write-Output @"
    javar -c : run a Java class <c> from parent directory
"@

    Write-Host "Latex:" -ForegroundColor Cyan  
    Write-Output @"
    getmeta : open meta.tex file in VS Code
"@

    Write-Host "Linux:" -ForegroundColor Red
    Write-Output @"
    ubu -p : open path <p> in VS Code connected to Ubuntu WSL
"@

    Write-Host "C/C++:" -ForegroundColor DarkCyan
    Write-Output @"
    Add '$mingw' to the PATH to use g++ and gcc
"@

    Write-Host "VMs:" -ForegroundColor Magenta
    Write-Output @"
    redhat_old : SSH into old Red Hat VM
"@
}

# original working directory
$owd = (Get-Location).Path
$dh = "shaikfai@dh2026pc02.utm.utoronto.ca"

function touch {
    param (
        [Parameter(Mandatory=$true)]
        [string]$file
    )

    if (-Not (Test-Path $file)) {
        New-Item -Path $file -ItemType File
    }

    Set-ItemProperty -Path $file -Name LastWriteTime -Value (Get-Date)
}

function hp {
    clear
    function global:prompt {
        Write-Host ("> ") `
        -ForegroundColor Cyan -NoNewline
        return " `b" # returns an empty string and preventts defaulting to 'PS> ' (would happen if  we just returned "")
    }
    # note the reasosn i want to return an empty string is because of how virtual environments affect the prompt when activated.
    # before i had Write-Host(">") and return " " but that would make the prompt look like ">(env)  " instead of "> (env) ".
}

function spp { # sp alias is taken 
    function global:prompt {
        "$(if (Test-Path variable:/PSDebugContext) { '[DBG]: ' } else { '' })$(Get-Location)> "
    }
}


function shortcut_path { 
    # return the path a shortcut (.lnk) file points to
    param (
        [Parameter(Mandatory=$true)]
        [string]$shortcutFile
    )

    # check if the shortcut file exists
    if (-Not (Test-Path $shortcutFile)) {
        Write-Host "Shortcut file not found: $shortcutFile" -ForegroundColor Red
        return
    }

    # check if the shortcut file is a .lnk file
    if ($shortcutFile -notlike "*.lnk") {
        Write-Host "File is not a .lnk shortcut: $shortcutFile" -ForegroundColor Red
        return
    }

    # create a WScript.Shell COM object
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut((Resolve-Path $shortcutFile).Path)

    # check if the shortcut object was created successfully
    if ($null -eq $shortcut) {
        Write-Host "Failed to create shortcut object for: $shortcutFile" -ForegroundColor Red
        return
    }

    # get the target path of the shortcut
    $targetPath = $shortcut.TargetPath

    # check if the target path was retrieved successfully
    if ([string]::IsNullOrEmpty($targetPath)) {
        Write-Host "Failed to retrieve target path for: $shortcutFile" -ForegroundColor Red

        # debug
        Write-Host "DEBUG INFO:" -ForegroundColor Red
        $shortcut | Get-Member -MemberType Properties | ForEach-Object {
            $property = $_.Name
            $value = $shortcut.$property
            Write-Host "${property}: ${value}" -ForegroundColor Yellow
        }

        return
    }

    # output the target path
    return $targetPath
}

function sizeof() {
    # returns the size of the file or directory
    param (
        [Parameter(Mandatory=$true)]
        [string]$path,

        [switch]$mb
    )

    $file = Get-Item $path | Select-Object -First 1

    if ($mb) {
        $sizeInMB = [math]::Round($file.Length / 1MB, 2)
        echo "$($file.Name) size: $sizeInMB MB"
        return
    }
    $sizeInGB = [math]::Round($file.Length / 1GB, 2)
    echo "$($file.Name) size: $sizeInGB GB"
}

Set-Alias np notepad.exe

# ========================== general ==========================
# =============================================================
#
#
# =============================================================
# ========================== profile ==========================

function bash_ref {
    . $PROFILE
}

function bash_pull {
    code $PROFILE
}

# ========================== profile ==========================
# =============================================================
#
#
# =============================================================
# ============================ git ============================

function Push-AllRemotes {
    git remote | ForEach-Object { git push $_ master }
}

function Pull-AllRemotes {
    git remote | ForEach-Object { git pull $_ master }
}

Set-Alias pushall Push-AllRemotes
Set-Alias pullall Pull-AllRemotes

# ============================ git ============================
# =============================================================
#
#
# =============================================================
# ========================== python ===========================

function ppath { 
    # returns the path to the python executable of the specified version
    param(
        [Parameter(Mandatory=$true)]
        [string]$v
    )
    return "${HOME}\.pyenv\pyenv-win\versions\$v\python.exe"
}

function actenv { 
    # activate the specified virtual environment
    param(
        [Parameter(Mandatory=$true)]
        [string]$n
    )
    $path = "$envdir\$n\Scripts\activate.ps1"
    if (Test-Path $path) {
        $command = ". `"$path`""
        Invoke-Expression $command
        Write-Host "activated virtual environment $n" -ForegroundColor Green
    } else {
        Write-Host "virtual environment $n not found" -ForegroundColor Red
    }
}

function makenv { 
    # creates a virtual environment with the specified python version
    param(
        [Parameter(Mandatory=$false)]
        [string]$n = "env",
        [Parameter(Mandatory=$false)]
        [string]$v
    )

    $curr_py = (python --version).Substring(7)

    if (!$v) {
        $response = Read-Host "no python version specified, use current: $curr_py (y) ?"
        if ($response -ne "y") {
            Write-Host "rejected confirm" -ForegroundColor Red
            return
        }
        $path="none"
        $v = $curr_py
    } else {
        $path = ppath -v $v
    }

    $response = Read-Host "make a python env `"$n`" with version $v in pwd (y) ?"
    if ($response -ne "y") {
        Write-Host "rejected confirm" -ForegroundColor Red
        return
    }

    try {
        if ($path -eq "none") {
            try {
                virtualenv $n
                Write-Host "virtual environment `"$n`" created with current python version $curr_py" -ForegroundColor Green
            } catch {
                Write-Host "error creating virtual environment" -ForegroundColor Red
                return
            }
            return
        }
        if (!(Test-Path $path)) {
            $response = Read-Host "python version $v not found, install (y) ?"
            if ($response -ne "y") {
                Write-Host "rejected confirm" -ForegroundColor Red
                return
            }
            try {
                pyenv install $v
            } catch {
                Write-Host "error installing python version $v" -ForegroundColor Red
                return
            }
        }
        virtualenv -p $path $n
        Write-Host "virtual environment `"$n`" created with version $v" -ForegroundColor Green
    } catch {
        Write-Host "error creating virtual environment" -ForegroundColor Red
    }
}

function inenv {
    if ($env:VIRTUAL_ENV) { $env:VIRTUAL_ENV } else { "not in a virtual environment" }
}

# ========================== python ===========================
# =============================================================
#
#
# =============================================================
# =========================== conda ===========================

Set-Alias -Name condarev -Value "conda init --reverse" 

# =========================== conda ===========================
# =============================================================
#
#
# =============================================================
# =========================== java ============================

function javar {
    # run a Java class from parent directory
    param (
        [Parameter(Mandatory=$true)]
        [string]$className
    )
    $currDir = Split-Path -Path (Get-Location) -Leaf
    cd ..
    java "$currDir.$className"
    cd $currDir
}

# =========================== java ============================
# =============================================================
#
#
# =============================================================
# ============================ C ==============================

# this is the path to the mingw64 bin directory
# activate it by running: $env:PATH += ";C:\msys64\mingw64\bin"
$mingw = "C:\msys64\mingw64\bin"

# ============================ C ==============================
# =============================================================
#
#
# =============================================================
# ========================== latex ============================

function getmeta() {
    code "C:\same\profiles\meta.tex"
}

# ========================== latex ============================
# =============================================================
#
#
# =============================================================
# ========================== linux ============================

function ubu {
    # opens the current path as a project in vscode connected to ubuntu
    $dir = (Get-Location).Path -replace '\\', '/'  # convert our pwd path in windows to mounted linux path
    $dir = '/mnt/' + $dir.Substring(0,1).ToLower() + $dir.Substring(2)
    code --remote wsl+Ubuntu $dir
}

# ========================== linux ============================
# =============================================================
#
#
#
# =============================================================
# =========================== vim =============================

Set-PSReadLineOption -EditMode Vi

# =========================== vim =============================
# =============================================================
#
#
#
# =============================================================
# ========================== nvim =============================

# ========================== nvim =============================
# =============================================================
#
#
#
# =============================================================
# ============================ VMs ============================

function redhat_old {
    ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -c 3des-cbc hacker@10.10.10.12
}

function redscp {
    # requires the source and destination to be in the form "user@host:/path/to/file"
    param (
        [Parameter(Mandatory=$true)]
        [string]$source,
        [Parameter(Mandatory=$true)]
        [string]$destination,

        [switch]$r
    )

    if ($r) {
        scp -r -oKexAlgorithms=+diffie-hellman-group1-sha1 -c 3des-cbc $source $destination
        return
    }
    scp -oKexAlgorithms=+diffie-hellman-group1-sha1 -c 3des-cbc $source $destination
}

function ubu804xsi () {
    ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa arnold@192.168.10.128
}

function ubu804 () {
    ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa student@192.168.10.100
}

# ============================ VMs ============================
# =============================================================
#
#
#
# // ========================================================//
# //===================== CONFIGURATION =====================//

$device_register = 'C:\same_2\device_name.txt' # this file contains the device name
if (-Not (Test-Path $device_register)) {
    $device_name = ""
}
else {
    $device_name = Get-Content -Path $device_register -TotalCount 1
}

$default_envdir = Join-Path -Path $HOME -ChildPath ".envs" # by default, we use this directory for virtual environments
switch ($device_name) {
    "ACER-DK" { $envdir = 'D:\.envs'
                $fall_courses = "D:\735-D\school\university\uoft\year-3\fall"
              }
    "FS-LAPTOP" { $envdir = 'C:\.envs'
                  $fall_courses = "C:\735\university\uoft\year-3\fall"
                }
    default { 
        $envdir = $default_envdir
    }
}

if (-Not (Test-Path $envdir)) {
        Write-Host "WARNING: python env directory not found: $envdir. create it or configure profile.ps1" -ForegroundColor Yellow
}

# //===================== CONFIGURATION =====================//
# // ========================================================//
#
#
#
# // ========================================================//
# //========================= SCRIPT ========================//
hp
