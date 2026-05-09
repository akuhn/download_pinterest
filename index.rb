#!/usr/bin/env ruby
require %(options_by_example)

require_relative 'lib/fetch_boards'


$flags = OptionsByExample.read(DATA).parse(ARGV)

downloaded = 0
total = 0

pinterest = FetchBoards.new
pinterest.each_pin.map do |each_pin|
  fname = File.join('images', "#{each_pin['id']}.jpg")
  downloaded += 1 if File.exist?(fname)
  total += 1
end

puts "downloaded: #{downloaded}"
puts "total: #{total}"


__END__
Count Pinterest pins and downloaded images.

Usage: index.rb [options] [cookie_file]

Options:
  -p, --partition PARTITION     Cache partition name
