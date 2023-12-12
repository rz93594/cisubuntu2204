#!/usr/bin/env bash

if ! command -v git2 &> /dev/null
then
    echo "git could not be found"
    sudo apt update -y && sudo apt install git -y
    git clone https://github.com/rz93594/cisubuntu2204.git
else
    git clone https://github.com/rz93594/cisubuntu2204.git
fi

