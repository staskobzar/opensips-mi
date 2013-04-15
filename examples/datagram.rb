#!/usr/bin/env ruby
require 'opensips/mi'

opensips = Opensips::MI.connect :datagram, 
                                :host => "192.168.122.128", 
                                :port => 8809

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
# fifo get_statistics 
puts "."*80
r = opensips.get_statistics('dialog','tm')
puts "get_statistics Response: #{r.code}" if r

# uptime command and response
puts "."*80
r = opensips.uptime
puts "Since: #{r.since}"
puts "Uptime: #{r.uptime}"

# store, fetch and delete data from cache
puts "."*80
opensips.cache_store('local','mykey','myvalue')
r = opensips.cache_fetch('local','mykey')

if r.respond_to? :mykey
  puts "Restored value 'mykey' from cache local: #{r.mykey}"
  opensips.cache_remove('local','mykey')
  puts "Value removed from cache"
else
  puts "Failed to fetch. Error message: " << r.inspect
end

# get contact details
puts "."*80
contact = opensips.ul_show_contact('location', 'alice')
if contact.respond_to? :first
  puts "Contact 'alice' details"
  puts "  contact: " << contact.first[:contact]
  puts "  user agent: " << contact.first[:user_agent]
else
  puts "Failed to get contact. Error message: " << r.message
end

# Successfull response contains array of contact hashs:
# [{
#   :contact=>"<sip:7747@voipdomain.com>", 
#   :q=>nil, 
#   :expires=>"68", 
#   :flags=>"0x0", 
#   :cflags=>"0x0", 
#   :socket=>"<udp:voip.proxy.com:5060>", 
#   :methods=>"0x1F7F", 
#   :user_agent=>"<PolycomSoundStationIP-SSIP_6000-UA/3.3.5.0247_0004f2f18103>"
#   }]

puts "."*80
# get current dialogs
begin
  dlg = opensips.dlg_list
  puts "Active calls: %d" % dlg.size
rescue => e
  puts "Failed to get dialogs list: " << e.message
end

puts "."*80
# Send NOTIFY request
puts "Send NOTIFY to alice@127.0.0.1:5066"
res = opensips.uac_dlg "NOTIFY", "sip:alice@127.0.0.1:5066", 
                  {
                    "From"  => "<sip:alice@wanderland.com>;tag=8755a8d01a12f7e903a6f4ccaf393f04",
                    "To"    => "<sip:alice@wanderland.com>",
                    "Event" => "check-sync"
                  }
puts "  Response code: " << res.code.to_s
puts "  Response message: " << res.message
puts "  Response data: " << res.data.inspect


puts "."*80
# Restart Polycom phone
# use ul_show_contact to to get contact URI
res = opensips.event_notify 'sip:alice@127.0.0.1:5060', :polycom_check_cfg
puts "Restart Polycom phone"
puts "  Response code: " << res.code.to_s
puts "  Response message: " << res.message
puts "  Response data: " << res.data.inspect

# send MWI notify
puts "."*80
res = opensips.mwi_update 'sip:alice@wanderland.com:5060', 'sip:*97@voicemail.pbx.com', 5
puts "Send MWI"
puts "  Response code: " << res.code.to_s
puts "  Response message: " << res.message
puts "  Response data: " << res.data.inspect


