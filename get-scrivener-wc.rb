#!/Users/merovex/.rvm/rubies/ruby-2.4.1/bin/ruby

# To make this work, add a keyword "Wordcounted" into the Scrivener Project Keywords.

require "awesome_print"
require 'date'
require 'yaml'

@year = Date.today.year
ydir = "./#{@year}/words"
Dir.mkdir(ydir) unless File.exist?(ydir)

kw = "<Title>Wordcounted<\/Title>"
data = {}
Dir["/Users/merovex/Writing/**/*.scrivx"].each do |filename|
  next if open(filename) { |f| f.grep(/#{kw}/) }.empty?

  name = File.basename(filename, '.scrivx')

  line = open(filename).grep(/PreviousSession/)[0]
  words = (/Words="(\d+)"/.match(line)[1]).to_i
  date = DateTime.parse(/Date=\"([^\"]+?)\"/.match(line)[1]).strftime("%Y-%m-%d")
  data[date] = {total: 0, projects: []} if data[date].nil?
  data[date][:projects] << {
    name: name,
    date: date,
    words: words
  }
  data[date][:total] += words
end
#
data.each do |date, d|
  fn = "#{ydir}/#{date}.yml"
  File.open(fn, 'w') {|f| f.write d.to_yaml }
end
