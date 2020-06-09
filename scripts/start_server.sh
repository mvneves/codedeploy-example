#!/bin/bash

cd /home/ubuntu
export FLASK_APP=hello.py
flask run --host=0.0.0.0 --port 8080 &