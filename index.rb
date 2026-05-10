#!/usr/bin/env ruby
require %(options_by_example)

require_relative 'lib/client'


$flags = OptionsByExample.read(DATA).parse(ARGV)

pinterest = Client.new('.response_cache.sqlite', $flags.get(:partition))

if $flags.include_list_partitions?
  puts pinterest.cache.list_partitions
  exit
end

if $flags.include_drop_partition?
  dropped_entries = pinterest.cache.drop_partition!($flags.get :drop_partition)
  puts "dropped #{dropped_entries} entries from partition #{$flags.get(:drop_partition)}"
  exit
end

size = 0
downloaded = 0
total = 0

pinterest.each_pin do |each_pin|
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
  -l, --list-partitions         Print known cache partitions and exit
  -D, --drop-partition NAME     Delete entries for given partition and exit
  -p, --partition PARTITION     Cache partition name
