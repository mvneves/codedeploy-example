#!/bin/bash

pid=`pgrep flask`
if [ -n  "$pid" ]
then
	kill $pid
fi
