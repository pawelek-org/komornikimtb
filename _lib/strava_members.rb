require 'yaml'
require 'strava-ruby-client'

filename = './.var-keys/_strava_kmtb_members.key'

members_from_yaml = YAML.load(File.read(filename))
members = members_from_yaml

i = 0
members_from_yaml.each do |member|
  next unless member[:active] == 1
  i += 1
  oauth_client = Strava::OAuth::Client.new(
    client_id: member[:strava][:client_id],
    client_secret: member[:strava][:client_id]
  )
  response = oauth_client.oauth_token(
    refresh_token: member[:strava][:refresh_token],
    grant_type: 'refresh_token'
  )
  refresh_token = response.refresh_token
  if refresh_token != member[:strava][:refresh_token]
    members[i][:strava][:refresh_token] = "#{refresh_token}"
    File.open(filename, "w") { |file| file.write(members.to_yaml) }
  end 
  Strava::Api::Client.new(access_token: response.access_token)
  puts Strava.client.athlete.username
end  

#p members_from_yaml

