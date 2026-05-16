#!/usr/bin/env ruby
require %(fileutils)
require %(options_by_example)
require %(set)

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

if $flags.include_trash?
  pin_ids = pinterest.each_pin.map { it['id'] }.to_set
  Dir.glob('images/**/*')
    .select { File.file?(it) }
    .reject { pin_ids.include?(File.basename(it, %(.*))) }
    .sort
    .each do |path|
      puts path
      FileUtils.mv(path, File.expand_path('~/.Trash')) unless $flags.include_dry?
    end
  exit
end

downloaded = 0
total = 0
files = Dir.glob('images/**/*').select { File.file?(it) }
indexed_files = files.to_set
files_by_id = Hash.new { |hash, key| hash[key] = [] }
files.each { |path| files_by_id[File.basename(path, %(.*))] << path }

pinterest.each_pin do |each_pin|
  paths = files_by_id[each_pin['id']]
  paths.each { indexed_files.delete(it) }
  downloaded += 1 if paths.any?
  total += 1
end

not_indexed_files = indexed_files.to_a.sort
size = files.sum { File.size(it) }
size_mb = size / 1024.0 / 1024.0
downloaded_percent = total.zero? ? 0 : 100 * downloaded / total

puts "pins: #{total}"
puts "downloaded images: #{downloaded} (#{downloaded_percent}%)"
puts "not-indexed images: #{not_indexed_files.length}"
puts "cached requests: #{pinterest.cache.count_cached_responses}"
puts "total files: #{files.length}"
puts format('total size: %.2f MB', size_mb)

not_indexed_files.each { puts it }


__END__
Count Pinterest pins and downloaded images.

Usage: index.rb [options] [cookie_file]

Options:
  -l, --list-partitions         Print known cache partitions and exit
  -D, --drop-partition NAME     Delete entries for given partition and exit
      --trash                   Move unreferenced downloaded files to macOS trash
      --dry                     Print trash candidates without moving them
  -p, --partition PARTITION     Cache partition name
