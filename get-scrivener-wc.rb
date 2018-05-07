#!/Users/merovex/.rvm/rubies/ruby-2.4.1/bin/ruby

# To make this work, add a keyword "Wordcounted" into the Scrivener Project Keywords.
require 'net/http'
# require "awesome_print"
require 'date'
require 'yaml'
require 'uri'
require 'json'
# exit
class Integer
  def to_hours
    return (self.to_f / 3600.0).round(1)
  end
  def to_wph(seconds)
    seconds = 60 if seconds < 60
    (self.to_f / seconds.to_f * 3600.0).round(0)
  end
end

def getWph(words, seconds)
  (words.to_f / seconds.to_f * 3600.0).round(0)
end
def getHours(seconds)
  (seconds.to_f / 3600.0).round(1)
end
def setDataForDate()
  {total: {words: 0, wph: 0, seconds: 0, hours: 0.0}, projects: []}
end
# TODO: Check if online, otherwise don't do time check.
def getRescueTimeSecondsForProjectDate(project, date)
  # return 0
  begin
    q = {
      key: 'B63UlcNcdr6uHO1U8S4bgyrhSiGJoI81m8G5A9dy',
      perspective: 'interval',
      resolution_time: 'day',
      restrict_begin: date,
      restrict_end: date,
      restrict_kind: 'activity',
      restrict_thing: 'scrivener',
      restrict_thingy: project,
      format: 'json'
    }
    url = "https://www.rescuetime.com/anapi/data?#{URI.encode_www_form(q)}"
    seconds = JSON.parse(Net::HTTP.get(URI.parse(url)))["rows"].first[1]
  rescue
    # Can't get on the network, can't return non-zero sicne we later divide by seconds.
    return 60
  end
end


@year = Date.today.year
ydir = "./#{@year}"
Dir.mkdir(ydir) unless File.exist?(ydir)

@kw = "<Title>Wordcounted<\/Title>"
@data = {}
@data[Date.today.strftime('%Y-%m-%d')] = setDataForDate()

Dir["/Users/merovex/Writing/**/*.scrivx"].each do |filename|

  # Skip the project unless we have flagged that Scrivener project to be counted.
  next if open(filename) { |f| f.grep(/#{@kw}/) }.empty?

  project_name = File.basename(filename, '.scrivx')

  # Get Scrivener Wordcount & Date
  line = open(filename).grep(/PreviousSession/)[0]
  words = (/Words="(\d+)"/.match(line)[1]).to_i
  date = DateTime.parse(/Date=\"([^\"]+?)\"/.match(line)[1]).strftime("%Y-%m-%d")

  # Get Corresponding RescueTime data
  seconds = getRescueTimeSecondsForProjectDate(project_name, date)

  # Initialize the Date bucket.
  @data[date] = setDataForDate() if @data[date].nil?

  # Add the Scrivener / RescueTime to Date Bucket
  @data[date][:projects] << {
    name: project_name,
    date: date,
    seconds: seconds,
    hours: seconds.to_hours,
    wph: words.to_wph(seconds),
    words: words
  }

  # Update Totals
  @data[date][:total][:updated_at] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  @data[date][:total][:words] += words
  @data[date][:total][:seconds] += seconds
  @data[date][:total][:hours] = @data[date][:total][:seconds].to_hours
  @data[date][:total][:wph] = @data[date][:total][:words].to_wph(@data[date][:total][:seconds])
end
#
@data.each do |date, d|
  fn = "#{ydir}/#{date}.yml"
  File.open(fn, 'w') {|f| f.write d.to_yaml }
end
