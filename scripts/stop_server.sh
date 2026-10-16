#!/bin/bash

pid=`pgrep -f "flask run"`
if [ -n  "$pid" ]
then
	kill $pid
fi
