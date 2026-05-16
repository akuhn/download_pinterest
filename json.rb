#!/usr/bin/env ruby
require %(json)
require %(options_by_example)

require_relative 'lib/client'


def summarize_pin(pin)
  pin
    .reject { |key, _| %w{images videos}.include?(key) }
    .merge('images' => "#{pin.fetch('images', {}).length} image sizes omitted; pass --full to include")
end

$flags = OptionsByExample.read(DATA).parse(ARGV)

pinterest = Client.new('.response_cache.sqlite', $flags.get(:partition), offline: $flags.include_offline?)

id = File.basename($flags.get(:fname), %(.*))
pin = pinterest.each_pin.find { it['id'] == id }
abort "WARN: pin not found: #{id}" unless pin

json = JSON.generate($flags.include_full? ? pin : summarize_pin(pin))

if system('which', 'jq', out: '/dev/null', err: '/dev/null')
  IO.popen(%w{jq -C .}, 'w') { |jq| jq.write(json) }
else
  puts JSON.pretty_generate(JSON.parse(json))
end


__END__
Pretty print pin JSON matched by filename.

Usage: json.rb [options] fname

Options:
  -f, --full                    Include full pin JSON
      --offline                 Fail on cache miss instead of fetching
  -p, --partition PARTITION     Cache partition name
