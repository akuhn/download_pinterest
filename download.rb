#!/usr/bin/env ruby
require %(fileutils)
require %(json)
require %(net/http)
require %(options_by_example)
require %(uri)

require_relative 'lib/client'


$flags = OptionsByExample.read(DATA).parse(ARGV)

resolution = $flags.get(:resolution)
resolutions = %w(orig 736x 474x 236x 170x 136x136)
resolutions = resolutions.drop_while { it != resolution }
fail "Unknown resolution: #{resolution}" if resolutions.empty?


pins = []
pinterest = Client.new('.response_cache.sqlite', $flags.get(:partition))
pinterest.each_pin do |each_pin|
  url = resolutions.filter_map { each_pin.dig('images', it, 'url') }.first
  puts url if $flags.include?(:fetch)
  pins << [each_pin, url] if url
end

unless $flags.include?(:fetch)
  FileUtils.mkdir_p('images')

  pins = pins.shuffle
  $flags.if_present(:limit) { pins = pins.first(it) }

  pins.each do |each_pin, url_with_selected_resolution|
    uri = URI(url_with_selected_resolution)
    extension = File.extname(uri.path)
    extension = '.jpg' if extension.empty?
    path = "images/#{each_pin['id']}#{extension}"
    next if File.exist?(path)

    puts "Downloading #{path}..."
    response = Net::HTTP.get_response(uri)
    fail "Could not download #{url_with_selected_resolution}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    File.binwrite(path, response.body)
  end
end

if $flags.include?(:interactive)
  binding.pry
end


__END__
Fetch pin image URLs from all Pinterest boards.

Usage: download.rb [options] [cookie_file]

Options:
  -p, --partition PARTITION     Cache partition name
  -r, --resolution ENUM         Image resolution to print (default 736x)
      --fetch                   Print image URLs instead of downloading
  -n, --limit NUM               Limit number of URLs/downloads
  -i, --interactive             Open a Pry session after parsing the response
