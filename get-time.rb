#!/Users/merovex/.rvm/rubies/ruby-2.4.1/bin/ruby

require "awesome_print"
require 'rescue_time_api'
require 'yaml'

@client = RescueTimeApi::Client.new(key: "")

@year = Date.today.prev_day.year

Date.new(Date.today.prev_day.year, 01, 01).upto(Date.today) do |date|
  fn = "./#{@year}/time/#{date}.yml"
  unless File.exist?(fn) and false
    d = {}
    response = @client.request({
      prespective: 'interval',
      resolution_time: 'day',
      restrict_begin: date
    })
    response.rows.each do |r|
      if r['activity'].downcase == 'scrivener'
        d = r
        d['hours'] = (d['seconds'].to_f / 3600).round(1)
        break
      end
    end
    File.open(fn, 'w') {|f| f.write d.to_yaml }
  end
end
