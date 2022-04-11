require 'yaml'
require 'strava-ruby-client'

filename = './.var-keys/_strava_kmtb_members.key'

members_from_yaml = YAML.load(File.read(filename))
members = members_from_yaml

members_from_yaml.each_with_index do |member, index|
  next unless member[:active] == 1
  
  ### Strava API OAuth
  oauth_client = Strava::OAuth::Client.new(
    client_id: member[:strava][:client_id],
    client_secret: member[:strava][:client_secret]
  )
  response = oauth_client.oauth_token(
    refresh_token: member[:strava][:refresh_token],
    grant_type: 'refresh_token'
  )
  refresh_token = response.refresh_token
  if refresh_token != member[:strava][:refresh_token]
    members[index][:strava][:refresh_token] = "#{refresh_token}"
    File.open(filename, "w") { |file| file.write(members.to_yaml) }
  end 
  client = Strava::Api::Client.new(access_token: response.access_token)
  
  ### Strava::Models::Athlete
  ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/athlete.rb
  athlete = client.athlete
  
  ### Strava::Models::ActivityStats
  ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/activity_stats.rb
  athlete_stats = client.athlete_stats(athlete.id)
  
  ### Array[Strava::Models::Activity]
  ### https://github.com/dblock/strava-ruby-client#list-athlete-activities
  athlete_activities = client.athlete_activities
  
    ### Single activity
    ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/activity.rb
    #activity = client.activity(1982980795)

    ### Activity Photos
    ### https://github.com/dblock/strava-ruby-client/blob/master/lib/strava/models/photo.rb
    #photos = client.activity_photos(1982980795)

  break
end  

#p members_from_yaml

