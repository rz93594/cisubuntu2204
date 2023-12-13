#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "running cis script v2 from $SCRIPT_DIR" >> /var/tmp/cislog.txt
export TERM=linux

if ! command -v git &> /dev/null
then
    echo "git could not be found"
    sudo apt update -y && sudo apt install git -y
    cd /var/tmp
    git clone https://github.com/rz93594/cisubuntu2204.git
    echo "Git downloaded"
    cd cisubuntu2204
    source ./cis-lbk_ubuntu_22.04_LTS-v1.0.0.sh -y
else
    cd /var/tmp
    git clone https://github.com/rz93594/cisubuntu2204.git
    echo "Git downloaded"
    cd cisubuntu2204
    source ./cis-lbk_ubuntu_22.04_LTS-v1.0.0.sh -y
fi

