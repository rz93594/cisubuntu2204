# cisubuntu2204

## Pre-work during install -  Edge + Edge-dev should be already installed
```bash
sudo apt install software-properties-common apt-transport-https wget -y
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main"
sudo apt install microsoft-edge-dev -y
sudo apt update -y
sudo apt upgrade -y
```

## Intune install
```bash
sudo apt install curl gpg -y
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list'
sudo rm microsoft.gpg
sudo apt update -y
sudo apt install intune-portal -y
```

## Optional to run hardeningscript by hand, defaults to L1W (if other is wanted modify header of script

* Get setup.sh file from https://github.com/rz93594/cisubuntu2204/setup.sh
* execute setup.sh

## Changes made primary CIS script
```bash
## added tmw, simple check to look for -y and will add call CONFIRM later if no -y
## add diff patch
args=("$@")
echo ${args[0]} >> /var/tmp/output.txt
FLAG=${args[0]}

if [ "$FLAG"="-y" ]; then
        echo "Program execution not called correctly, see todd wilkinson"
        exit
fi
## Modified header to force L1W
```

## removed CONFIRM function from functions/nix_warning_banner.sh but commenting out CONFIRM



