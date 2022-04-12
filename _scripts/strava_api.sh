#!/bin/bash

#set -e
#set -o pipefail

git pull

# 1. clubrides
bundle exec rake strava:clubrides
STRAVA_FILE="./_pages/jezdzimy.md"
dt=$(date '+%Y-%m-%d %H:%M:%S');
if [ -f $STRAVA_FILE ]; then
  git add $STRAVA_FILE
  git commit -m "Strava clubrides: $dt"
fi

# 2. members
bundle exec rake strava:members
STRAVA_FILE="./_data/strava_members.yml"
dt=$(date '+%Y-%m-%d %H:%M:%S');
if [ -f $STRAVA_FILE ]; then
  git add $STRAVA_FILE
  git commit -m "Strava members: $dt"
fi

git push
