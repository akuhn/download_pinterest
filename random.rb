#!/usr/bin/env ruby
require %(options_by_example)

require_relative 'lib/client'


$flags = OptionsByExample.read(DATA).parse(ARGV)
$flags.expect_at_most_one_of(:uniform, :older, :recent, :stale, :larger)
$flags.expect_at_most_one_of(:partition, :yesterday)


paths = []
partition = $flags.include_yesterday? ? :yesterday : $flags.get(:partition)
pinterest = Client.new('.response_cache.sqlite', partition)
pinterest.each_pin do |pin|
  fname = "images/#{pin['id']}.jpg"
  paths << fname if File.file?(fname)
end

num_samples = $flags.get(:num)

score =
  if $flags.include_older?
    ->(path) { File.mtime(path) }
  elsif $flags.include_recent?
    ->(path) { -File.mtime(path).to_i }
  elsif $flags.include_stale?
    ->(path) { File.atime(path) }
  elsif $flags.include_larger?
    ->(path) { -File.size(path) }
  end

paths = paths.sort_by(&score) if score

selected = []
num_samples.times do
  break if paths.empty?

  random = score ? rand * rand * rand : rand
  selected << paths.delete_at((random * paths.length).floor)
end

selected.each do |each|
  puts each
  system('open', each)
end


__END__
Open random downloaded Pinterest images.

Usage: random.rb [options] [cookie_file]

Options:
      --larger                  Open largest images
      --older                   Open oldest images
      --recent                  Open most recent images
      --stale                   Open least recently accessed images
      --uniform                 Pick uniformly (this is the default)
  -n, --num NUM                 Number of downloaded images to open (default 10)
  -p, --partition PARTITION     Cache partition name
  -y, --yesterday               Pick the most recent partition that is not today
