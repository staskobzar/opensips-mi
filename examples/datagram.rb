#!/usr/bin/env ruby
require 'opensips/mi'

# Connect to Opensips using transport interface
# Raises exception on errors
begin
  opensips = Opensips::MI.connect :datagram, 
                                  :host => "192.168.122.128", 
                                  :port => 8809
rescue => e
  puts "Failed connect to OpenSIPs MI"
  puts ">> " << e.message
end

# Using command method
puts "."*80
puts "== Command: opensips.command('which')"
response = opensips.command('which')
puts "* Response code: %d" % response.code
puts "* Response message: %s" % response.message
if response.success # bool
  puts "* Available commands:"
  puts "\t" << response.rawdata.inspect
end

# using interface to command method
# fifo help command
puts "."*80
puts "== Command: opensips.help('get_statistics')"
r = opensips.help('get_statistics')
puts "* Response code: %d" % response.code
puts "* Response message: %s" % response.message

# Multiple parameters for command interface
puts "."*80
puts "== Command: opensips.get_statistics('dialog','tm')"
response = opensips.get_statistics('dialog','tm')
puts "* Response code: %d" % response.code
puts "* Response message: %s" % response.message

# uptime command and response
puts "."*80
puts "== Command: opensips.uptime"
response = opensips.uptime
r = response.result
puts "* Response code: %d" % response.code
puts "* Response message: %s" % response.message
puts "** Since: #{r.since}" if r.success
puts "** Uptime (sec): #{r.uptime}" if r.success

# store, fetch and delete data from cache
puts "."*80
puts "== Command: opensips.cache_store('local','mykey','myvalue')"
opensips.cache_store('local','mykey','myvalue')
puts "* Store cahce: opensips.cache_store('local','mykey','myvalue')"
r = opensips.cache_fetch('local','mykey')
if r.success
  puts "* Restored value 'mykey' from cache local: #{r.result.mykey}"
  opensips.cache_remove('local','mykey')
  puts "* Value removed from cache: opensips.cache_remove('local','mykey')"
else
  puts "Failed to fetch. Error message: " << r.message
end

# get contact details
puts "."*80
puts "== Command: opensips.ul_show_contact('location', 'alice')"
res = opensips.ul_show_contact('location', 'alice')
contact = res.result
if res.success
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
puts "== Command: opensips.dlg_list"
dlg = opensips.dlg_list
if dlg.success
  puts "* Active calls: %d" % dlg.result.size
else
  puts "- Failed to get dialogs list: " << e.message
end

puts "."*80
# Send NOTIFY request
puts "== Send NOTIFY to alice@127.0.0.1:5066"
res = opensips.uac_dlg "NOTIFY", "sip:alice@127.0.0.1:5066", 
                  {
                    "From"  => "<sip:alice@wanderland.com>;tag=8755a8d01a12f7e903a6f4ccaf393f04",
                    "To"    => "<sip:alice@wanderland.com>",
                    "Event" => "check-sync"
                  }
puts "* Response code: " << res.code.to_s
puts "* Response message: " << res.message
puts "* Response data: " << res.rawdata.inspect

# Restart Polycom phone
# use ul_show_contact to to get contact URI
puts "."*80
res = opensips.event_notify 'sip:alice@127.0.0.1:5060', :polycom_check_cfg
puts "== Restart Polycom phone"
puts "* Response code: " << res.code.to_s
puts "* Response message: " << res.message
puts "* Response data: " << res.rawdata.inspect

# send MWI notify 'alice' about 5 new voicemails
puts "."*80
res = opensips.mwi_update 'sip:alice@wanderland.com:5060', 'sip:*97@voicemail.pbx.com', 5
puts "== Send MWI"
puts "* Response code: " << res.code.to_s
puts "* Response message: " << res.message
puts "* Response data: " << res.rawdata.inspect

