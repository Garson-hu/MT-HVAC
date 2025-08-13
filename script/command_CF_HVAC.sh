#!/bin/bash


set -x 
LD_PRELOAD=Path_To_Your_HVAC_Client/libhvac_client.so python3 Path_To_Your_Code/train.py -d

# echo DONE `hostname`