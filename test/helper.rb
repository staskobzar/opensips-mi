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
end
