# Setup

These are my dotfiles for Windows. Here's how to set up.

## Prequisites
You need `gsudo` for the scripts to work.

```bash
# install scoop
Set-ExectutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethond -Uri https://get.scoop.sh | Invoke-Expression

# install gsudo
scoop install gsudo

# clone repo
cd ~
git clone git@github.com:mrdandelion6/.winfiles.git
```
You can install `gsudo` any way you like , I use scoop for simplicity.

## Run Scripts
```bash
cd ~/.winfiles

# optionally backup existing winfiles before overriding
./backup_winfiles.ps1

# override existing files
./override_winfiles.ps1
```
You will be prompted by `gsudo` to give admin access , press OK.
