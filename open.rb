#!/usr/bin/env ruby
require %(options_by_example)


$flags = OptionsByExample.read(DATA).parse(ARGV)

id = File.basename($flags.get(:fname), %(.*))
system('open', "https://www.pinterest.com/pin/#{id}/")


__END__
Open Pinterest pins.

Usage: open.rb fname
