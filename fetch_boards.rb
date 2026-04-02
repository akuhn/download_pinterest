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

cookie = read_cookie(cookie_file)
abort("Cookie content is empty in #{cookie_file}") if cookie.empty?

uri = URI("https://www.pinterest.com/resource/BoardsResource/get/")
options = {
  privacy_filter: "all",
  sort: "last_pinned_to",
  field_set_key: "profile_grid_item",
  filter_stories: false,
  username: username,
  page_size: 25,
  group_by: "mix_public_private",
  include_archived: true,
  redux_normalize_feed: true,
  filter_all_pins: true
}

params = {
  source_url: "/#{username}/",
  data: { options: options, context: {} }.to_json,
  _: (Time.now.to_f * 1000).to_i
}
uri.query = URI.encode_www_form(params)

request = Net::HTTP::Get.new(uri)
request["accept"] = "application/json, text/javascript, */*, q=0.01"
request["accept-language"] = "en-US,en;q=0.9"
request["cookie"] = cookie
request["priority"] = "u=1, i"
request["referer"] = "https://www.pinterest.com/"
request["screen-dpr"] = "2"
request["sec-ch-ua"] = "\"Chromium\";v=\"146\", \"Not-A.Brand\";v=\"24\", \"Google Chrome\";v=\"146\""
request["sec-ch-ua-full-version-list"] = "\"Chromium\";v=\"146.0.7680.76\", \"Not-A.Brand\";v=\"24.0.0.0\", \"Google Chrome\";v=\"146.0.7680.76\""
request["sec-ch-ua-mobile"] = "?0"
request["sec-ch-ua-model"] = "\"\""
request["sec-ch-ua-platform"] = "\"macOS\""
request["sec-ch-ua-platform-version"] = "\"14.1.2\""
request["sec-fetch-dest"] = "empty"
request["sec-fetch-mode"] = "cors"
request["sec-fetch-site"] = "same-origin"
request["user-agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36"
request["x-app-version"] = "a9c2b33"
request["x-b3-flags"] = "0"
request["x-b3-parentspanid"] = "750f02beeefb9a1f"
request["x-b3-spanid"] = "1e20db7aa7ac34cd"
request["x-b3-traceid"] = "750f02beeefb9a1f"
request["x-pinterest-appstate"] = "active"
request["x-pinterest-pws-handler"] = "www/[username].js"
request["x-pinterest-source-url"] = "/#{username}/"
request["x-requested-with"] = "XMLHttpRequest"

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

puts "HTTP #{response.code}"
begin
  puts JSON.pretty_generate(JSON.parse(response.body))
rescue JSON::ParserError
  puts response.body
end
