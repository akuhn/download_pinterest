#!/usr/bin/env ruby

require "json"
require "net/http"
require "uri"

username = ARGV[0] || "example_user"
cookie_file = ARGV[1] || "curl.txt"

abort("Cookie file not found: #{cookie_file}") unless File.exist?(cookie_file)

def read_cookie(file)
  text = File.read(file).strip
  return text if text.empty?

  from_curl = text.match(/(?:^|\s)-(?:b|--cookie)\s+(['"])(.*?)\1/m)
  return from_curl[2] if from_curl

  text
end

def read_csrf(cookie)
  part = cookie.split(";").map(&:strip).find { |piece| piece.start_with?("csrftoken=") }
  return nil unless part

  part.split("=", 2)[1]
end

cookie = read_cookie(cookie_file)
abort("Cookie content is empty in #{cookie_file}") if cookie.empty?
csrf = read_csrf(cookie)

uri = URI("https://www.pinterest.com/resource/BoardsResource/get/")
options = {
  username: username,
  page_size: 25,
  sort: "last_pinned_to",
  privacy_filter: "all",
  field_set_key: "profile_grid_item",
  filter_stories: false,
  group_by: "mix_public_private",
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
request["accept"] = "application/json, text/javascript, */*, q=0.01"
request["accept-language"] = "en-US,en;q=0.9"
request["cookie"] = cookie
request["referer"] = "https://www.pinterest.com/"
request["user-agent"] = "Mozilla/5.0"
request["x-app-version"] = "a9c2b33"
request["x-pinterest-appstate"] = "active"
request["x-pinterest-pws-handler"] = "www/[username].js"
request["x-pinterest-source-url"] = "/#{username}/"
request["x-requested-with"] = "XMLHttpRequest"
request["x-csrftoken"] = csrf if csrf && !csrf.empty?

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

puts "HTTP #{response.code}"
begin
  puts JSON.pretty_generate(JSON.parse(response.body))
rescue JSON::ParserError
  puts response.body
end
