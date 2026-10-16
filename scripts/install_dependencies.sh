#!/bin/bash

# Ubuntu 20.04 ou mais novo: não há mais Python 2 e o pip global é bloqueado (PEP 668),
# então o Flask é instalado pelo pacote da distribuição
sudo apt-get update
sudo apt-get install -y python3-flask
