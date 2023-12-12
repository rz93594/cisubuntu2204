# cisubuntu2204

## Pre-work during install -  Edge + Edge-dev should be already installed
```bash
sudo apt install software-properties-common apt-transport-https wget
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main"
sudo apt install microsoft-edge-dev
sudo apt update
sudo apt upgrade
```

## Intune install
```bash
sudo apt install curl gpg
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list'
sudo rm microsoft.gpg
sudo apt update
sudo apt install intune-portal
```

## Optional to run hardeningscript by hand, defaults to L1W (if other is wanted modify header of script

* Get setup.sh file from https://github.com/rz93594/cisubuntu2204/setup.sh
* execute setup.sh

