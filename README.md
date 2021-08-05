Komorniki MTB Team Site
=======================

![Komorniki MTB Team Logo](https://github.com/pawelek-org/komornikimtb/raw/main/assets/images/komornikimtb.png "Komorniki MTB Team Logo")

We are the local cycling organization located in [Komorniki](https://en.wikipedia.org/wiki/Komorniki) ([Greater Poland](https://en.wikipedia.org/wiki/Greater_Poland)). Our mission is to deliver the cycling sporting success, grow and effectively inspire and support people to cycle regularly.

**Live URL** (in polish): [komornikimtb.pl](https://komornikimtb.pl)

### Resources

1. [Jekyll](https://jekyllrb.com/)
2. [Memoirs theme](https://github.com/wowthemesnet/jekyll-theme-memoirs)
3. [Netlify CMS](https://www.netlifycms.org/)
4. [Netlify](https://www.netlify.com/)
5. [Strava Ruby Client](https://github.com/dblock/strava-ruby-client)
6. [Github](https://github.com/)

![Netlify Status](https://api.netlify.com/api/v1/badges/0c8407b7-2baa-4dc3-b3e9-910fc9a1f3b4/deploy-status)

### Local installation

1. You will need [Ruby](https://www.ruby-lang.org/en/) and [Bundler](https://bundler.io/) to use [Jekyll](https://jekyllrb.com/). Following [Using Jekyll with Bundler](https://jekyllrb.com/tutorials/using-jekyll-with-bundler/) to fullfill the enviromental requirement.

2. Install the dependencies specified in your `Gemfile`:

```sh
$ bundle install 
```

3. Serve the local website (`localhost:4000` by default):

```sh
$ bundle exec jekyll serve --watch --livereload
```

### Netlify CMS

Netlify CMS is a single-page app that you pull into the `/admin` part of this site. It uses `git-gateway` authorization method.

Read more about Netlify CMS [Core Concepts](https://www.netlifycms.org/docs/intro/).

See the configuration located in `/admin/config.yml`.

### Strava Ruby Client

Latest club bike rides are fetched from [Strava API](https://developers.strava.com/docs/reference/#api-Clubs-getClubActivitiesById) via [Strava Ruby Client](https://github.com/dblock/strava-ruby-client). In order to use you need to add token variables obtained from My API Application in the Strava UI.

```sh
ENV['STRAVA_CLIENT_ID']
ENV['STRAVA_CLIENT_SECRET']
ENV['STRAVA_API_REFRESH_TOKEN']
ENV['STRAVA_API_CLUB_ID']
```

Run this command to execute the Strava script in the context of the current bundle (`Rakefile`):
```sh
$ bundle exec rake strava:clubrides --trace
```

### Production

The directory `/_site` is where the generated site will be placed (by default) once Jekyll is done transforming it.

```sh
$ JEKYLL_ENV=production bundle exec rake strava:clubrides && bundle exec jekyll build --config _config.yml,_config_prod.yml
```

### Contributing

You're encouraged to submit pull requests, propose features and discuss issues.

### License

MIT License (See [LICENSE.txt](./LICENSE.txt))

