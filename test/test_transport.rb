require 'helper'

describe Opensips::MI::Transport, "testing MI transport layers" do
  before do
    @fifo_params = {:fifo_name => '/tmp/opensips_fifo'}
  end

  after do
  end

  describe "test fifo transport layer" do
    it "must retrun fifo class instance" do
      File.stubs(:exists?).once.returns(true)
      File.stubs(:pipe?).twice.returns(true)
      Kernel.stubs(:system).returns(true)
      Opensips::MI.connect(:fifo,@fifo_params).must_be_instance_of Opensips::MI::Transport::Fifo
    end

    it "must raise when using unknown transport method" do
      proc {
        Opensips::MI.connect(:unknown_transport_method,{})
      }.must_raise NameError
    end

    it "must raise when no fifo_name parameter passed" do
      proc {
        Opensips::MI.connect :fifo, {}
      }.must_raise ArgumentError
    end

    it "must raise when fifo_name file not exists" do
      File.stubs(:exists?).once.returns(false)
      proc {
        Opensips::MI.connect :fifo, :fifo_name => '/file/not/exists'
      }.must_raise ArgumentError
    end

    it "must raise when fifo_name file is not pipe" do
      File.stubs(:exists?).once.returns(true)
      File.stubs(:pipe?).once.returns(false)
      proc {
        Opensips::MI.connect :fifo, :fifo_name => '/tmp/opensips_fifo'
      }.must_raise ArgumentError
    end

    it "must raise if fifo reply directory not exists" do
      Dir.stubs(:exists?).once.returns false
      proc {
        Opensips::MI.connect :fifo, :fifo_name => '/tmp/opensips_fifo',
                                    :reply_dir => '/tmp'
      }.must_raise ArgumentError
    end

    it "must set attributes for class instance" do
      Dir.stubs(:exists?).once.returns(true)
      File.stubs(:exists?).once.returns(true)
      File.stubs(:pipe?).once.returns(true)
      directory = '/tmp/opensips/fifo'
      fifo_name = '/tmp/opensips_fifo'
      replayfifo= 'fifo_reply_file_name'
      fifo = Opensips::MI::Transport::Fifo.new  :fifo_name  => fifo_name,
                                                :reply_dir  => directory,
                                                :reply_fifo => replayfifo
      fifo.reply_dir.must_equal directory
      fifo.fifo_name.must_equal fifo_name
      fifo.reply_dir.must_equal directory
    end

    it "must create temporary fifo reply file" do
      fifo = init_class_fifo
      Kernel.stubs(:system).returns(true)
      File.stubs(:pipe?).returns(true)
      fifo.open
    end

    it "must raise if can not create reply fifo" do
      fifo = init_class_fifo
      Kernel.stubs(:system).returns(true)
      File.stubs(:pipe?).returns(false)
      proc { fifo.open }.must_raise SystemCallError
    end

    it "must send command to fifo" do
      fifo = Opensips::MI.connect(:fifo,@fifo_params)
      fifo.command 'which'
    end

  end
end
