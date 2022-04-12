file_strava = './.var-keys/_strava_kmtb_members.yml'
file_log = './.var-keys/_strava_kmtb_members.log'
file_data = './_data/strava_members.yml'
require 'yaml'
require 'strava-ruby-client'
require 'logger'
logger = Logger.new(file_log, 5, 1024000)

def get_members_data_from_strava(file_strava, file_log, logger)

  members_from_strava = YAML.load(File.read(file_strava))
  update_members = members_from_strava

  members_from_strava.each_with_index do |member, index|
    next unless member['active'] == 1
    #next unless member['strava_api']['client_id'] == 123456
    
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
      logger.error("Strava API OAuth #{e.message} (client_id: #{member['strava_api']['client_id']})")
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
    update_members[index]['athlete']['id'] = athlete.id
    update_members[index]['athlete']['username'] = athlete.username
    update_members[index]['athlete']['firstname'] = athlete.firstname
    update_members[index]['athlete']['lastname'] = athlete.lastname
    update_members[index]['athlete']['display_name'] = athlete.firstname + " " + athlete.lastname
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
          'distance'          => athlete_stats.ytd_ride_totals.distance.distance_in_kilometers_s,
          'moving_time'       => athlete_stats.ytd_ride_totals.moving_time,
          'elevation_gain'    => athlete_stats.ytd_ride_totals.elevation_gain
        }
      }
    end
    
    ### Array[Strava::Models::Activity]
    ### https://github.com/dblock/strava-ruby-client#list-athlete-activities
    #athlete_activities = client.athlete_activities
    
      ### Single activity
      ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/activity.rb
      #activity = client.activity(1982980795)

      ### Activity Photos
      ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/photo.rb
      #photos = client.activity_photos(1982980795)

    logger.info("OK ==> id:#{athlete.id} - #{athlete.firstname} #{athlete.lastname}")
    sleep(0.5) # half a second
  end
  File.open(file_strava, "w") { |file| file.write(update_members.to_yaml) }
end


def parse_members_data(file_strava, file_data)

  def distance_in_meters(distance)
    return if distance.nil?
    format('%gkm', format('%.2f', distance / 1000))
  end

  def elevation_in_meters(elevation)
    return if elevation.nil?
    format('%gm', format('%.1f', elevation))
  end
  
  def seconds_to_hms(seconds)
    return if seconds.nil?
    "%02dh %02dm %02ds" % [seconds / 3600, seconds / 60 % 60, seconds % 60]
  end

  members_from_strava = YAML.load(File.read(file_strava))
  members_data = []

  members_from_strava.each_with_index do |member, index|
    next unless member['active'] == 1
    data = {
      'name'        => member['athlete']['display_name'],
      'id'          => member['athlete']['id'],
      'profile'     => member['athlete']['profile'],
      'strava_url'  => "https://www.strava.com/athletes/#{member['athlete']['id']}",
      'stats'       => {
        'biggest_ride_distance'         => distance_in_meters(member['athlete']['stats']['biggest_ride_distance']),
        'biggest_climb_elevation_gain'  => elevation_in_meters(member['athlete']['stats']['biggest_climb_elevation_gain']),
        'recent_ride_totals'            => {
          'count'           => member['athlete']['stats']['recent_ride_totals']['count'],
          'distance'        => distance_in_meters(member['athlete']['stats']['recent_ride_totals']['distance']),
          'moving_time'     => seconds_to_hms(member['athlete']['stats']['recent_ride_totals']['moving_time']),
          'elevation_gain'  => elevation_in_meters(member['athlete']['stats']['recent_ride_totals']['elevation_gain'])
        },
        'ytd_ride_totals'               => {
          'count'           => member['athlete']['stats']['ytd_ride_totals']['count'],
          'distance'        => distance_in_meters(member['athlete']['stats']['ytd_ride_totals']['distance']),
          'moving_time'     => seconds_to_hms(member['athlete']['stats']['ytd_ride_totals']['moving_time']),
          'elevation_gain'  => elevation_in_meters(member['athlete']['stats']['ytd_ride_totals']['elevation_gain'])
        }
      }
    }
    members_data << data
  end

  File.open(file_data, "w") { |file| file.write(members_data.to_yaml) }
end

# Step 1
#get_members_data_from_strava file_strava, file_log, logger

# Step 2
parse_members_data file_strava, file_data