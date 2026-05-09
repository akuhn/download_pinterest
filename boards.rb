#!/usr/bin/env ruby
require %(json)
require %(options_by_example)

require_relative 'lib/fetch_boards'


$flags = OptionsByExample.read(DATA).parse(ARGV)

pinterest = FetchBoards.new
pinterest.each_board do |each|
  puts "#{each['pin_count'].to_s.rjust(8)}  #{each['name']}"
end

if $flags.include?(:interactive)
  binding.pry
end


__END__
Fetch user boards from Pinterest.

Usage: boards.rb [options] [cookie_file]

Options:
  -p, --partition PARTITION     Cache partition name
  -i, --interactive             Open a Pry session after parsing the response
