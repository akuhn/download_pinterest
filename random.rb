#!/usr/bin/env ruby
require %(options_by_example)

require_relative 'lib/fetch_boards'


$flags = OptionsByExample.read(DATA).parse(ARGV)


paths = []
pinterest = FetchBoards.new('.response_cache.sqlite', $flags.get(:partition))
pinterest.each_pin.map do |each_pin|
  fname = File.join('images', "#{each_pin['id']}.jpg")
  paths << fname if File.exist?(fname)
end

paths.sample($flags.get :limit).each do |each|
  system('open', each)
end


__END__
Open random downloaded Pinterest images.

Usage: random.rb [options] [cookie_file]

Options:
  -n, --limit NUM               Number of downloaded images to open (default 10)
  -p, --partition PARTITION     Cache partition name
