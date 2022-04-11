require 'yaml'
require 'strava-ruby-client'

filename = './.var-keys/_strava_kmtb_members.yaml'

members_from_yaml = YAML.load(File.read(filename))
update_members = members_from_yaml

members_from_yaml.each_with_index do |member, index|
  next unless member['active'] == 1
  #next unless member['strava_api']['client_id'] == 123456
  
  ### Strava API OAuth
  oauth_client = Strava::OAuth::Client.new(
    client_id: member['strava_api']['client_id'],
    client_secret: member['strava_api']['client_secret']
  )
  response = oauth_client.oauth_token(
    refresh_token: member['strava_api']['refresh_token'],
    grant_type: 'refresh_token'
  )
  refresh_token = response.refresh_token
  if refresh_token != member['strava_api']['refresh_token']
    update_members[index]['strava_api']['refresh_token'] = "#{refresh_token}"
  end 
  client = Strava::Api::Client.new(access_token: response.access_token)
  
  ### Strava::Models:'athlete'
  ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/athlete.rb
  athlete = client.athlete
  update_members[index]['athlete']['id'] = athlete.id
  update_members[index]['athlete']['username'] = athlete.username
  update_members[index]['athlete']['updated_at'] = athlete.updated_at
  if athlete.profile.present?
    update_members[index]['athlete']['profile'] = athlete.profile
  end
  
  ### Strava::Models::ActivityStats
  ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/activity_stats.rb
  athlete_stats = client.athlete_stats(athlete.id)
  if athlete_stats.present?
    update_members[index]['athlete']['stats'] = athlete_stats
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

  #break
end  

File.open(filename, "w") { |file| file.write(update_members.to_yaml) }



