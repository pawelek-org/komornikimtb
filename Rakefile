# Strava API
# https://developers.strava.com/docs/reference/#api-Clubs-getClubActivitiesById
# bundle exec rake strava:clubrides --trace
desc 'Generate recent club rides from Strava.'
namespace :strava do
  task :strava_members do
    require './_lib/strava_members'
  end

  task :clubrides do
    require 'hashie'
    require 'strava-ruby-client'
    require './_lib/strava'
    #require './_lib/map'
    require './_lib/activity'
    require 'fileutils'
    require 'down'
    require 'polylines'
    require 'dotenv/load'

    activities_options = { per_page: 30, id: ENV['STRAVA_API_CLUB_ID'] }
    activities = Strava.client.club_activities(activities_options.merge(page: 1))

    clubrides_filename = "./_pages/jezdzimy.md"
    File.open clubrides_filename, 'w' do |file|
      file.write <<-EOS
---
layout: page
title: Jeździmy na rowerach :)
permalink: /jezdzimy
comments: false
image: assets/images/kmtb/kmtb008.jpg
imageshadow: true
---

Poniższa tabela prezentuje [ostatnie jazdy rowerowe](https://www.strava.com/clubs/336381){:target="_blank"} naszych klubowiczów na podstawie aktywności w serwisie Strava. Dane zostały automatycznie pobrane poprzez [Strava API](https://developers.strava.com/docs/reference/#api-Clubs-getClubActivitiesById){:target="_blank"} w dniu #{Time.now.getgm.getlocal("+02:00").strftime('%Y-%m-%d %H:%M')}.

Lp. | Nazwa | Imię | Dystans [km] | Czas [min] | Wysokość [m]
:--- | :--- | :---: | ---: | ---: | ---:
      EOS
      page = 1
      i = 0
      loop do
        break unless activities.any?
        activities.each do |activity|
          next unless activity.type == 'Ride'
          i += 1
          row = Array.new
          distance = activity.distance / 1000
          distance = distance.truncate(2)
          time = activity.moving_time / 60
          time = time.truncate(2)
          gain = format('%.d', activity.total_elevation_gain)
          row << i
          row << activity.name.gsub("|", "")
          row << activity.athlete.firstname.gsub("|", "")
          row << distance
          row << time
          row << gain
          file.write "#{row.join("|")}\n"
          break if i >= 30
        end
        break if i >= 30
        page += 1
        activities = Strava.client.club_activities(activities_options.merge(page: page))
      end
    end
    puts clubrides_filename
  end
end