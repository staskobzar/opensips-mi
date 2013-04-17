require 'simplecov'
require 'coveralls'
Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start 

require 'minitest/autorun'
require 'mocha/setup'
require 'stringio'
require 'opensips/mi'

class MiniTest::Unit::TestCase

  def init_class_fifo
    Dir.stubs(:exists?).once.returns(true)
    File.stubs(:exists?).once.returns(true)
    File.stubs(:pipe?).once.returns(true)
    directory = '/tmp/opensips/fifo'
    fifo_name = '/tmp/opensips_fifo'
    replayfifo= 'fifo_reply_file_name'
    Opensips::MI::Transport::Fifo.new  :fifo_name  => fifo_name,
                                       :reply_dir  => directory,
                                       :reply_fifo => replayfifo
  end

  def response_data_cmd_which
    Array[
      "200 OK", "get_statistics", "reset_statistics", "uptime", "version", 
      "pwd", "arg", "which", "ps", "kill", "debug", "cache_store", 
      "cache_fetch", "cache_remove", "event_subscribe", "help", "list_blacklists", 
      "t_uac_dlg", "t_uac_cancel", "t_hash", "t_reply", "ul_rm", "ul_rm_contact", 
      "ul_dump", "ul_flush", "ul_add", "ul_show_contact", "ul_sync", ""
    ]
  end

  def response_uldump
    fix = File.expand_path('fixtures/ul_dump',File.dirname(__FILE__))
    File.readlines(fix).map{|l| l.chomp}
  end

  def response_contacts
    [
      "200 OK",
      "Contact:: <sip:7747@10.132.113.198>;q=;expires=100;flags=0x0;cflags=0x0;socket=<udp:10.130.8.21:5060>;methods=0x1F7F;user_agent=<PolycomSoundStationIP-SSIP_6000-UA/3.3.5.0247_0004f2f18103>",
      "Contact:: <sip:7747@10.130.8.100;line=628f4ffdfa7316e>;q=;expires=3593;flags=0x0;cflags=0x0;socket=<udp:10.130.8.21:5060>;methods=0xFFFFFFFF;user_agent=<Linphone/3.5.2 (eXosip2/3.6.0)>",
      "",
    ]
  end

  def response_dlg_list
    fix = File.expand_path('fixtures/dlg_list',File.dirname(__FILE__))
    File.readlines(fix).map{|l| l.chomp}
  end
  
end
