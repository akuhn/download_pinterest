#!/usr/bin/env ruby

require %(json)
require %(options_by_example)

require_relative 'lib/fetch_boards'


$flags = OptionsByExample.read(DATA).parse(ARGV)
interactive = $flags.get(:interactive)
body = FetchBoards.new.run

begin
  data = JSON.parse(body)

  if interactive
    puts data.keys
    binding.pry
  else
    puts JSON.pretty_generate(data)
  end
rescue JSON::ParserError
  puts body
end

__END__
Fetch user boards from Pinterest.

Usage: fetch_boards.rb [options] [username] [cookie_file]

Options:
  -u, --user NAME               Pinterest username
  -p, --partition PARTITION     Cache partition name
  -i, --interactive             Open a Pry session after parsing the response
