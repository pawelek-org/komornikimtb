#!/bin/bash

JEKYLL_ENV=production

if [[ $INCOMING_HOOK_TITLE == "strava" && $NETLIFY ]] # if build is coming from netlify & build hook
then
  bundle exec rake strava:clubrides && bundle exec jekyll build --config _config.yml,_config_prod.yml
else
  bundle exec jekyll build --quiet --config _config.yml,_config_prod.yml
fi
