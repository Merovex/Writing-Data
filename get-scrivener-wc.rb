#!/Users/merovex/.rvm/rubies/ruby-2.4.1/bin/ruby

# To make this work, add a keyword "Wordcounted" into the Scrivener Project Keywords.
require 'net/http'
require "awesome_print"
require 'date'
require 'yaml'
require 'uri'
require 'json'

@year = Date.today.year
ydir = "./#{@year}"
Dir.mkdir(ydir) unless File.exist?(ydir)

kw = "<Title>Wordcounted<\/Title>"
data = {}


q = {
  key: '',
  perspective: 'interval',
  resolution_time: 'day',
  restrict_begin: '2018-04-30',
  restrict_end: '2018-04-30',
  restrict_kind: 'activity',
  restrict_thing: 'scrivener',
  restrict_thingy: 'Bellicose-2018',
  format: 'json'
}
url = "https://www.rescuetime.com/anapi/data?" + URI.encode_www_form(q)

def getWph(words, seconds)
  (words.to_f / seconds.to_f * 3600.0).round(0)
end
def getHours(seconds)
  (seconds.to_f / 3600.0).round(1)
end


Dir["/Users/merovex/Writing/**/*.scrivx"].each do |filename|

  # Skip the project unless we have flagged that Scrivener project to be counted.
  next if open(filename) { |f| f.grep(/#{kw}/) }.empty?

  # Get Scrivener Wordcount
  name = File.basename(filename, '.scrivx')
  line = open(filename).grep(/PreviousSession/)[0]
  words = (/Words="(\d+)"/.match(line)[1]).to_i

  # Get Corresponding RescueTime data
  date = DateTime.parse(/Date=\"([^\"]+?)\"/.match(line)[1]).strftime("%Y-%m-%d")
  q[:restrict_thingy] = name
  q[:restrict_begin] = q[:restrict_end] = date
  url = "https://www.rescuetime.com/anapi/data?#{URI.encode_www_form(q)}"

  seconds = JSON.parse(Net::HTTP.get(URI.parse(url)))["rows"].first[1]
  hours = (seconds.to_f / 3600.0).round(1)
  wph = (words.to_f / seconds.to_f * 3600.0).round(0)

  # Initialize the Date bucket.
  data[date] = {total: {words: 0, wph: 0, seconds: 0, hours: 0.0}, projects: []} if data[date].nil?

  # Add the Scrivener / RescueTime to Date Bucket
  data[date][:projects] << {
    name: name,
    date: date,
    seconds: seconds,
    hours: getHours(seconds),
    wph: getWph(words, seconds),
    words: words
  }

  # Update Totals
  data[date][:total][:words] += words
  data[date][:total][:seconds] += seconds
  data[date][:total][:hours] = getHours(data[date][:total][:seconds])
  data[date][:total][:wph] = getWph(data[date][:total][:words], data[date][:total][:seconds])
end
#
data.each do |date, d|
  fn = "#{ydir}/#{date}.yml"
  File.open(fn, 'w') {|f| f.write d.to_yaml }
end
