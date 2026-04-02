#!/usr/bin/env ruby

require %(date)
require %(json)
require %(net/http)
require %(options_by_example)
require %(uri)
require_relative 'cache'


flags = OptionsByExample.read(DATA).parse(ARGV)

def read_cookie(file)
  text = File.read(file).strip
  return text if text.empty?

  text.match(/(?:^|\s)-(?:b|--cookie)\s+(['"])(.*?)\1/m)&.captures&.last || text
end

def read_csrf(cookie)
  cookie.split(';').map(&:strip).find { |piece| piece.start_with?('csrftoken=') }&.split('=', 2)&.last
end

def fetch_boards(username, cookie)
  csrf = read_csrf(cookie)
  uri = URI('https://www.pinterest.com/resource/BoardsResource/get/')
  options = {
    username: username,
    page_size: 25,
    sort: 'last_pinned_to',
    privacy_filter: 'all',
    field_set_key: 'profile_grid_item',
    filter_stories: false,
    group_by: 'mix_public_private',
    include_archived: true,
    redux_normalize_feed: true,
    filter_all_pins: true,
  }

  params = {
    source_url: "/#{username}/",
    data: { options: options, context: {} }.to_json,
    _: (Time.now.to_f * 1000).to_i,
  }
  uri.query = URI.encode_www_form(params)

  request = Net::HTTP::Get.new(uri)
  {
    'accept' => 'application/json, text/javascript, */*, q=0.01',
    'accept-language' => 'en-US,en;q=0.9',
    'cookie' => cookie,
    'referer' => 'https://www.pinterest.com/',
    'user-agent' => 'Mozilla/5.0',
    'x-app-version' => 'a9c2b33',
    'x-pinterest-appstate' => 'active',
    'x-pinterest-pws-handler' => 'www/[username].js',
    'x-pinterest-source-url' => "/#{username}/",
    'x-requested-with' => 'XMLHttpRequest',
  }.each { |name, value| request[name] = value }
  request['x-csrftoken'] = csrf if csrf && !csrf.empty?

  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    response = http.request(request)
    puts "HTTP #{response.code}"
    response.body
  end
end


username = flags.get(:username) || 'example_user'
cookie_file = flags.get(:cookie_file) || 'curl.txt'
partition = flags.get(:partition) || Date.today.strftime('%Y-%m-%d')

abort("Cookie file not found: #{cookie_file}") unless File.exist?(cookie_file)
cookie = read_cookie(cookie_file)
abort("Cookie content is empty in #{cookie_file}") if cookie.empty?

cache = Cache.new('response_cache.sqlite', partition)
key = "boards:#{username}"
body = cache.fetch(key) do
  fetch_boards(username, cookie)
end

begin
  puts JSON.pretty_generate(JSON.parse(body))
rescue JSON::ParserError
  puts body
end

__END__
Fetch user boards from Pinterest.

Usage: fetch_boards.rb [options] [username] [cookie_file]

Options:
  -p, --partition PARTITION  Cache partition name
