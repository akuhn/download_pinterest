#!/usr/bin/env ruby
require %(json)
require %(options_by_example)

require_relative 'lib/fetch_boards'


$flags = OptionsByExample.read(DATA).parse(ARGV)

resolutions = %w(orig 736x 474x 236x 170x 136x136)
resolutions = resolutions.drop_while { |each| each != $flags.get(:resolution) }
fail "Unknown resolution: #{resolution}" if resolutions.empty?

pinterest = FetchBoards.new
pinterest.each_pin do |each_pin|
  puts resolutions.lazy.map { |each| each_pin.dig('images', each, 'url') }.first
end

if $flags.include?(:interactive)
  binding.pry
end


__END__
Fetch pin image URLs from all Pinterest boards.

Usage: fetch_pins.rb [options] [cookie_file]

Options:
  -p, --partition PARTITION     Cache partition name
  -r, --resolution ENUM         Image resolution to print (default 736x)
  -i, --interactive             Open a Pry session after parsing the response
