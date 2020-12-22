require 'dotenv/load'
require 'http'
require 'xmlhasher'
require 'erb'
require 'ostruct'
require 'mail'
require 'colorize'

SKIP = [15794, 17278, 17271]

class OpenStruct
  def get_binding
    binding()
  end
end

unless ENV['PLEX_TOKEN']
  puts "Error: Gotta create a .env file!".red
  exit 1
end

puts "Starting at #{Time.now.to_s}\n"

unless ENV['SEND']
  puts "\nRun again with SEND=1 to actually send emails\n".yellow
end

RECENT_SINCE = (Date.today - 7).to_time

movie_template = ERB.new(File.read('templates/movie.html.erb'))
index_template = ERB.new(File.read('templates/index.html.erb'))

# email addresses
response = HTTP.get("#{ENV['PLEX_HOSTNAME']}/api/users?X-Plex-Token=#{ENV['PLEX_TOKEN']}")
data = XmlHasher.parse(response.body)
emails = data[:MediaContainer][:User].collect do |user|
  user[:email]
rescue => e
  nil
end.compact

# total movie count
response = HTTP.get("#{ENV['LOCAL_HOSTNAME']}/library/sections/1/all?X-Plex-Token=#{ENV['PLEX_TOKEN']}")
data = XmlHasher.parse(response.body)
total_movie_count = data[:MediaContainer][:size].to_i

# total TV count
response = HTTP.get("#{ENV['LOCAL_HOSTNAME']}/library/sections/3/all?X-Plex-Token=#{ENV['PLEX_TOKEN']}")
data = XmlHasher.parse(response.body)
total_tv_count = data[:MediaContainer][:size].to_i

# loop through latest additions
response = HTTP.get("#{ENV['LOCAL_HOSTNAME']}/library/recentlyAdded?X-Plex-Token=#{ENV['PLEX_TOKEN']}")
data = XmlHasher.parse(response.body)
movies = data[:MediaContainer][:Video]

movies_html = movies.collect do |movie|
  added_at = Time.at(movie[:addedAt].to_i)
  genres = [movie[:Genre]].flatten.collect { |g| g[:tag] } rescue []
  id = if movie[:Media].kind_of? Array
    movie[:Media].first[:id].to_i
  else
    movie[:Media][:id].to_i
  end

  if added_at > RECENT_SINCE and !SKIP.include?(id)
    movie_struct = OpenStruct.new(movie.merge(:genres => genres))
    output = movie_template.result(movie_struct.get_binding)
  end
end.compact

index_struct = OpenStruct.new(
  movies: movies_html,
  total_movie_count: total_movie_count,
  total_tv_count: total_tv_count,
  recent_count: movies_html.size
)
index_html = index_template.result(index_struct.get_binding)

puts "Found #{total_movie_count} movies, #{total_tv_count} TV shows, #{movies_html.size} recently added\n".green

File.open('index.html', 'w') do |file|
  file.puts index_html
end
puts "Wrote index.html"

if ENV['SEND']
  puts "Sending to #{ENV['DEBUG'] ? ENV['EMAIL_TO'] : emails.join(', ')}..."
  print "Press Ctrl-C to cancel in next 5 seconds".yellow
  5.times do
    sleep 1
    print '.'.yellow
  end
  puts ''
  print 'Sending...'

  mail = Mail.new do
    from    ENV['EMAIL_FROM']
    to      ENV['EMAIL_TO']
    bcc     emails unless ENV['DEBUG']
    subject "New releases for week of #{(Date.today - Date.today.wday).strftime('%B %e, %Y')}"
    html_part do
      content_type 'text/html; charset=UTF-8'
      body index_html
    end
    delivery_method :smtp, address: ENV['FASTMAIL_HOSTNAME'],
                          port: ENV['FASTMAIL_PORT'],
                          enable_ssl: true,
                          user_name: ENV['FASTMAIL_USERNAME'],
                          password: ENV['FASTMAIL_PASSWORD']
  end
  mail.deliver
  print "sent to #{ENV['DEBUG'] ? 1 : emails.size} people\n\n"
else
  puts "Run with SEND=1 DEBUG=1 to send email only to Rob".yellow
end

