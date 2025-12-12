#!/usr/bin/env bash
set -eu

cd /functions

if [ ! -d "venv" ]
then
  python3 -m venv venv
  . venv/bin/activate
  pip install --upgrade pip==25.3
  if [ -f "requirements.txt" ]
  then
    pip install -r requirements.txt
  fi
else
  . venv/bin/activate
fi