if ENV['STRAVA_CLIENT_ID'].nil?
  ENV['STRAVA_CLIENT_ID'] = File.read('./.var-keys/_strava_client_id.key')
end
if ENV['STRAVA_CLIENT_SECRET'].nil?
  ENV['STRAVA_CLIENT_SECRET'] = File.read('./.var-keys/_strava_secret.key')
end
if ENV['STRAVA_API_REFRESH_TOKEN'].nil?
  ENV['STRAVA_API_REFRESH_TOKEN'] = File.read('./.var-keys/_strava_refresh.key')
end
if ENV['STRAVA_API_CLUB_ID'].nil?
  ENV['STRAVA_API_CLUB_ID'] = File.read('./.var-keys/_strava_club_id.key')
end

module Strava
  def self.client
    @client ||= begin
      oauth_client = Strava::OAuth::Client.new(
        client_id: ENV['STRAVA_CLIENT_ID'],
        client_secret: ENV['STRAVA_CLIENT_SECRET']
      )

      response = oauth_client.oauth_token(
        refresh_token: ENV['STRAVA_API_REFRESH_TOKEN'],
        grant_type: 'refresh_token'
      )

      refresh_token = response.refresh_token
      if refresh_token != ENV['STRAVA_API_REFRESH_TOKEN']
        puts "The Strava API refresh token has changed, updating key file"
        File.write('./.var-keys/_strava_refresh.key', "#{refresh_token}")
      end

      Strava::Api::Client.new(access_token: response.access_token)
    end
  end
end
