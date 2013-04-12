#!/usr/bin/env ruby
require 'opensips/mi'

opensips = Opensips::MI.connect :fifo, 
                                :fifo_name => '/tmp/opensips_fifo',
                                :reply_dir => '/tmp'

puts "-"*40 + "send 'which' command to fifo"

# using command method
response = opensips.command('which')
puts "Response code: %d" % response.code
if response.success # bool
  response.data.each do |cmd| # data class member is array
    puts "\t#{cmd}"
  end
end
puts "="*80

puts "-"*40 + "send 'ul_dump' command to fifo"

# using interface to command method
# fifo help command
puts "."*80
r = opensips.help('get_statistics')
puts "help Response: #{r.code}"
# multiple parameters MUST be passed as array
# fifo get_statistics 
puts "."*80
r = opensips.get_statistics(['dialog','tm'])
puts "get_statistics Response: #{r.code}" if r

# uptime command and response
puts "."*80
r = opensips.uptime
puts "Since: #{r.since}"
puts "Uptime: #{r.uptime}"

# store, fetch and delete data from cache
puts "."*80
opensips.cache_store(['local','mykey','myvalue'])
r = opensips.cache_fetch(['local','mykey'])
puts "Restored value 'mykey' from cache local: #{r.mykey}"
opensips.cache_remove(['local','mykey'])
puts "Value removed from cache"

