require 'dotenv/load'
require 'http'
require 'xmlhasher'
require 'erb'
require 'ostruct'

class OpenStruct
  def get_binding
    binding()
  end
end

RECENT_SINCE = (Date.today - 7).to_time
TOKEN = "X-Plex-Token=#{ENV['PLEX_TOKEN']}"

response = HTTP.get("#{ENV['HOSTNAME']}/library/recentlyAdded?#{TOKEN}")
data = XmlHasher.parse(response.body)
movies = data[:MediaContainer][:Video]
movie_renderer = ERB.new(File.read('templates/movie.html.erb'))
index_renderer = ERB.new(File.read('templates/index.html.erb'))

movies_html = movies.collect do |movie|
  movie_struct = OpenStruct.new(movie)
  output = movie_renderer.result(movie_struct.get_binding)
end

index_struct = OpenStruct.new(:movies => movies_html)
index_struct.count = movies.size
index_html = index_renderer.result(index_struct.get_binding)

File.open('index.html', 'w') do |file|
  file.puts index_html
end

puts "Wrote index.html"
