#!/usr/bin/env ruby
require %(options_by_example)

require_relative 'lib/fetch_boards'


$flags = OptionsByExample.read(DATA).parse(ARGV)

size = 0
downloaded = 0
total = 0

pinterest = FetchBoards.new
pinterest.each_pin.map do |each_pin|
  fname = File.join('images', "#{each_pin['id']}.jpg")
  if File.exist?(fname)
    size += File.size(fname)
    downloaded += 1
  end
  total += 1
end

puts "size: #{(size / 1024.0 / 1024).round(2)} MB"
puts "downloaded: #{downloaded} (#{100 * downloaded / total}%)"
puts "total: #{total}"


__END__
Count Pinterest pins and downloaded images.

Usage: index.rb [options] [cookie_file]

Options:
  -p, --partition PARTITION     Cache partition name
