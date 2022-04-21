file_strava = './.var-keys/_strava_kmtb_members.yml'
file_log = './.var-keys/_strava_kmtb_members.log'
file_data = './_data/strava_members.yml'
require 'yaml'
require 'hashie'
require 'strava-ruby-client'
require 'fileutils'
require 'down'
require 'polylines'
require 'dotenv/load'
require 'digest'
require 'logger'
logger = Logger.new(file_log, 5, 1024000)

if ENV['MAPBOX_TOKEN'].nil?
  ENV['MAPBOX_TOKEN'] = File.read('./.var-keys/_mapbox_token.key')
end
if ENV['STATIC_MAPS_PATH'].nil?
  ENV['STATIC_MAPS_PATH'] = File.read('./.var-keys/_static_maps_path.key')
end

def get_members_data_from_strava(file_strava, file_log, logger)

  members_from_strava = YAML.load(File.read(file_strava))
  update_members = members_from_strava

  members_from_strava.each_with_index do |member, index|
    next unless member['active'] == 1
    #next unless member['strava_api']['client_id'] == 12345

    ### Strava API OAuth
    begin
      oauth_client = Strava::OAuth::Client.new(
        client_id: member['strava_api']['client_id'],
        client_secret: member['strava_api']['client_secret']
      )
      response = oauth_client.oauth_token(
        refresh_token: member['strava_api']['refresh_token'],
        grant_type: 'refresh_token'
      )
    rescue Strava::Errors::Fault => e
      logger.error("OAuth #{e.message} (client_id: #{member['strava_api']['client_id']})")
      next
    end

    refresh_token = response.refresh_token
    if refresh_token != member['strava_api']['refresh_token']
      logger.info("Strava API refresh token has changed (client_id: #{member['strava_api']['client_id']})")
      update_members[index]['strava_api']['refresh_token'] = "#{refresh_token}"
    end 
    
    client = Strava::Api::Client.new(access_token: response.access_token)

    ### Strava::Models:'athlete'
    ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/athlete.rb
    athlete = client.athlete
    display_name = athlete.firstname + " " + athlete.lastname
    username = I18n.transliterate(display_name.parameterize(separator: '-'))
    update_members[index]['athlete']['id'] = athlete.id
    update_members[index]['athlete']['firstname'] = athlete.firstname
    update_members[index]['athlete']['lastname'] = athlete.lastname
    update_members[index]['athlete']['display_name'] = display_name
    update_members[index]['athlete']['username'] = username
    update_members[index]['athlete']['updated_at'] = athlete.updated_at
    if athlete.profile.present?
      update_members[index]['athlete']['profile'] = athlete.profile
    end
    
    ### Strava::Models::ActivityStats
    ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/activity_stats.rb
    athlete_stats = client.athlete_stats(athlete.id)
    if athlete_stats.present?
      update_members[index]['athlete']['stats'] = {
        'biggest_ride_distance'         => athlete_stats.biggest_ride_distance,
        'biggest_climb_elevation_gain'  => athlete_stats.biggest_climb_elevation_gain,
        'recent_ride_totals'            => {
          'count'             => athlete_stats.recent_ride_totals.count,
          'distance'          => athlete_stats.recent_ride_totals.distance,
          'moving_time'       => athlete_stats.recent_ride_totals.moving_time,
          'elevation_gain'    => athlete_stats.recent_ride_totals.elevation_gain
        },
        'ytd_ride_totals'               => {
          'count'             => athlete_stats.ytd_ride_totals.count,
          'distance'          => athlete_stats.ytd_ride_totals.distance,
          'moving_time'       => athlete_stats.ytd_ride_totals.moving_time,
          'elevation_gain'    => athlete_stats.ytd_ride_totals.elevation_gain
        }
      }
    end

    ### Strava::Models::Activity
    ### https://github.com/dblock/strava-ruby-client#list-athlete-activities

    start_at = Time.now - 30*24*60*60 # 30 days ago
    activities_options = { per_page: 30, after: start_at }
    begin
      activities = client.athlete_activities(activities_options.merge(page: 1))
    rescue Strava::Errors::Fault => e
      logger.error("Activities ==> #{athlete.id} - #{username}")
      next
    end
   
    page = 1
    member_activities = []
    loop do
      break unless activities.any?
      activities.each do |activity|
        next unless activity.visibility == 'everyone'
        next unless activity.type == 'Ride' || activity.type == 'VirtualRide' || activity.type == 'Run' || activity.type == 'Swim'
        next if activity.commute == true
        next if activity.private == true
        #avg_speed_kmh = activity.average_speed.to_i * 3.6 # m/s to km/h
        if activity.type == 'Ride' || activity.type == 'VirtualRide'
          next if activity.distance.to_i < 15000 # at least 15km
          next if activity.total_elevation_gain.to_i < 10
        end
        if activity.type == 'Run'
          next if activity.distance.to_i < 1000 # at least 1km
          next if activity.total_elevation_gain.to_i < 5
        end
        ### Download PNG static map image from Mapbox.com
        map_url = nil
        if activity.map.summary_polyline.present? && File.directory?(ENV['STATIC_MAPS_PATH'])
          map_md5 = Digest::MD5.hexdigest(activity.map.summary_polyline)
          map_filename = "#{ENV['STATIC_MAPS_PATH']}/#{map_md5}.png"
          unless File.file?(map_filename)
            polyline_urlencoded = CGI.escape(activity.map.summary_polyline)
            mapbox_url = "https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/path-4+ef2929(#{polyline_urlencoded})/auto/800x800?access_token=#{ENV['MAPBOX_TOKEN']}"
            tempfile = Down.download(mapbox_url)
            FileUtils.mv(tempfile.path, map_filename)
            map_url = "https://static.komornikimtb.pl/maps/#{map_md5}.png"
          end
        end
        data = {
          'id'                    => activity.id,
          'start_date'            => activity.start_date_local,
          'type'                  => activity.type,
          'name'                  => activity.name,
          'strava_url'            => activity.strava_url,
          'type_emoji'            => activity.type_emoji,
          'distance'              => activity.distance_s,
          'moving_time'           => activity.moving_time_in_hours_s,
          'average_speed'         => activity.average_speed.positive? ? activity.kilometer_per_hour_s : nil,
          'total_elevation_gain'  => activity.total_elevation_gain.positive? ? activity.total_elevation_gain_s : nil,
          'map'                   => map_url,
          'pace'                  => nil,
          'photos'                => nil
        }
        if activity.type == 'Run'
          data['pace'] = activity.pace_per_kilometer_s
          data['average_speed'] = nil
        end
        if activity.type == 'Swim'
          data['pace'] = activity.pace_per_100_meters_s
          data['distance'] = activity.distance_in_meters_s
          data['average_speed'] = nil
        end
        photos = client.activity_photos(activity.id, size: '1200')
        if photos.any?
          urls = []
          photos.each do |photo|
            url = photo.urls['1200']
            urls << url
          end
          data['photos'] = urls
        end
        member_activities << data
      end
      page += 1
      activities = client.athlete_activities(activities_options.merge(page: page))
    end
    File.open("./_data/strava_activities_#{username}.yml", "w") { |file| file.write(member_activities.to_yaml) }

    logger.info("OK ==> #{athlete.id} - #{username}")
    sleep(0.5) # half a second
  end
  File.open(file_strava, "w") { |file| file.write(update_members.to_yaml) }
end


def parse_members_data(file_strava, file_data)

  def distance_to_km(distance)
    return if distance.nil?
    format('%gkm', format('%.2f', distance / 1000))
  end

  def elevation_to_m(elevation)
    return if elevation.nil?
    format('%gm', format('%.1f', elevation))
  end
  
  def seconds_to_hm(seconds)
    return if seconds.nil?
    "%02dh %02dm" % [seconds / 3600, seconds / 60 % 60]
  end

  members_from_strava = YAML.load(File.read(file_strava))
  members_data = []

  members_from_strava.each_with_index do |member, index|
    next unless member['active'] == 1
    data = {
      'name'        => member['athlete']['display_name'],
      'id'          => member['athlete']['id'],
      'profile'     => member['athlete']['profile'],
      'username'    => member['athlete']['username'],
      'strava_url'  => "https://www.strava.com/athletes/#{member['athlete']['id']}",
      'stats'       => {
        'biggest_ride_distance'         => distance_to_km(member['athlete']['stats']['biggest_ride_distance']),
        'biggest_climb_elevation_gain'  => elevation_to_m(member['athlete']['stats']['biggest_climb_elevation_gain']),
        'recent_ride_totals'            => {
          'count'           => member['athlete']['stats']['recent_ride_totals']['count'],
          'distance'        => distance_to_km(member['athlete']['stats']['recent_ride_totals']['distance']),
          'moving_time'     => seconds_to_hm(member['athlete']['stats']['recent_ride_totals']['moving_time']),
          'elevation_gain'  => elevation_to_m(member['athlete']['stats']['recent_ride_totals']['elevation_gain'])
        },
        'ytd_ride_totals'               => {
          'count'           => member['athlete']['stats']['ytd_ride_totals']['count'],
          'distance'        => distance_to_km(member['athlete']['stats']['ytd_ride_totals']['distance']),
          'moving_time'     => seconds_to_hm(member['athlete']['stats']['ytd_ride_totals']['moving_time']),
          'elevation_gain'  => elevation_to_m(member['athlete']['stats']['ytd_ride_totals']['elevation_gain'])
        }
      }
    }
    members_data << data
  end
  File.open(file_data, "w") { |file| file.write(members_data.to_yaml) }
end


def create_members_pages(file_data)

  dir_members = './_strava_members'
  members_data = YAML.load(File.read(file_data))

  members_data.each_with_index do |member, index|
    member['layout'] = 'strava_member'
    content = nil
    File.open("#{dir_members}/#{member['username']}.md", "w") { |file| file.write(member.to_yaml + content.to_yaml) }
  end

end

# Step 1
get_members_data_from_strava file_strava, file_log, logger

# Step 2
parse_members_data(file_strava, file_data)

# Step 3
create_members_pages(file_data)