require 'minitest/autorun'
require 'mocha/setup'
require 'stringio'
require 'opensips/mi'



require 'pp'

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
end
