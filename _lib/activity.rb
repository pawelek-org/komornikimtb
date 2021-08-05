class Strava::Models::Activity < Strava::Model
  #property :workout_type, from: 'workout_type', with: ->(data) {
  #  case data
  #  when 1 then 'race'
  #  when 2 then 'long run'
  #  when 3 then 'workout'
  #  else 'run'
  #  end
  #}

  #def to_s
  #  "name=#{name}, start_date=#{start_date_local}, distance=#{distance_s}, moving time=#{moving_time}, #{map}, elevation=#{total_elevation_gain_s}, #{calories}"
  #end

  def filename
    [
      "_posts/#{start_date_local.year}/#{start_date_local.strftime('%Y-%m-%d')}",
      #type.downcase,
      #distance_in_miles_s,
      #moving_time_in_hours_s
      id
    ].join('-') + '.md'
  end

  #def rounded_distance_in_miles_s
  #  format('%d-%0d', distance_in_miles, distance_in_miles + 1)
  #end

  #def round_up(n, increment)
  #  increment * (( n + increment - 1) / increment)
  #end

  #def rounded_pace_per_mile_s
  #  total_seconds = 1609.344 / average_speed
  #  minutes, seconds = total_seconds.divmod(60)
  #  # round the seconds to the nearest 15
  #  seconds = round_up(seconds.round, 15)
  #  if seconds == 60
  #    minutes += 1
  #    seconds = 0
  #  end
  #  seconds = seconds < 10 ? "0#{seconds}" : seconds.to_s
  #  "<#{minutes}m#{seconds}s/mi"
  #end
end
