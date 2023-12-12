#!/usr/bin/env bash

if ! command -v git &> /dev/null
then
    echo "git could not be found"
    sudo apt update -y && sudo apt install git -y
    git clone https://github.com/rz93594/cisubuntu2204.git
    echo "Git downloaded"
    cd cisubuntu2204
    source ./cis-lbk_ubuntu_22.04_LTS-v1.0.0.sh -y
else
    git clone https://github.com/rz93594/cisubuntu2204.git
    echo "Git downloaded"
    cd cisubuntu2204
    source ./cis-lbk_ubuntu_22.04_LTS-v1.0.0.sh -y
fi

