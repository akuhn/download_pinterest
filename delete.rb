#!/usr/bin/env ruby
require %(options_by_example)

require_relative 'lib/client'


$flags = OptionsByExample.read(DATA).parse(ARGV)

pinterest = Client.new('.response_cache.sqlite', $flags.get(:partition))

id = File.basename($flags.get(:fname), %(.*))
pinterest.delete_pin(id)
puts "Deleted #{id}"


__END__
Delete Pinterest pins.

Usage: delete.rb [options] fname

Options:
  -c, --cookie-file FILE        Cookie file (default default_curl.txt)
  -p, --partition PARTITION     Cache partition name
