#!/bin/bash

#set -e
#set -o pipefail

bundle exec rake strava:clubrides --trace
STRAVA_FILE="./_pages/jezdzimy.md"
dt=$(date '+%Y-%m-%d %H:%M:%S');

if [ -f $STRAVA_FILE ]; then
  git add $STRAVA_FILE
  git commit -m "Strava API update: $dt"
  git push
fi
