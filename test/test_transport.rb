require 'helper'

describe Opensips::MI::Transport, "testing MI transport layers" do
  before do
    @fifo_params = {:fifo_name => '/tmp/opensips_fifo'}
  end

  after do
  end

  # Fifo
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

    it "must raise when no fifo_nameInstanceOf.new parameter passed" do
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
      File.stubs(:exists?).returns(true)
      File.stubs(:pipe?).returns(true)
      IO.stubs(:sysopen).returns(5)
      io_obj = mock()
      io_obj.expects(:close).twice()
      io_obj.expects(:syswrite)
      io_obj.expects(:gets).returns(nil)
      IO.stubs(:open).twice().returns(io_obj)
      Opensips::MI::Response.expects(:new).returns(true)

      fifo = Opensips::MI.connect(:fifo,@fifo_params)
      fifo.command('which')
    end

  end
  # Datagram
  describe "test datagram transport layer" do
    it "must raise if empty host" do
      proc {
        Opensips::MI.connect :datagram, {}
      }.must_raise ArgumentError
    end

    it "must raise if empty port" do
      proc {
        Opensips::MI.connect :datagram, {:host => "10.10.10.10"}
      }.must_raise ArgumentError
    end

    it "must raise if invalid host" do
      host = "256.0.0.300"
      res = proc {
        Opensips::MI.connect :datagram, {:host => host, :port => 8088}
      }.must_raise SocketError
      res.message.must_match(/#{host}/)
    end

    it "must raise if invalid port" do
      proc {
        Opensips::MI.connect :datagram, {:host => "10.0.0.1", :port => (2**16 + 1)}
      }.must_raise SocketError
      
      proc {
        Opensips::MI.connect :datagram, {:host => "10.0.0.1", :port => 0}
      }.must_raise SocketError
    end
    
    it "must connect to socket" do
      UDPSocket.expects(:new).returns(mock(:connect => true))
      res = Opensips::MI.connect :datagram, 
                                 :host => "192.168.122.128", 
                                 :port => 8809
      res.respond_to?(:uac_dlg).must_equal true
    end

    it "must send valid command to socket" do
      cmd = 'command'
      params = ["aaa","bbb","ccc"]

      sock = mock('UDPSocket')
      sock.stubs(:connect)
      sock.stubs(:send).with([":#{cmd}:", *params].join(?\n) + ?\n, 0)
      sock.stubs(:recvfrom).returns( response_data_cmd_which )
      UDPSocket.expects(:new).returns(sock)
      res = Opensips::MI.connect :datagram, 
                                 :host => "192.168.122.128", 
                                 :port => 8809
      res.command(cmd, params).code.must_equal 200
    end

  end

  # XMLRPC
  describe "test xmlrpc transport layer" do
    it "must raise if empty host" do
      proc {
        Opensips::MI.connect :xmlrpc, {}
      }.must_raise ArgumentError
    end

    it "must raise if empty port" do
      proc {
        Opensips::MI.connect :xmlrpc, {:host => "10.10.10.10"}
      }.must_raise ArgumentError
    end

    it "must raise if invalid host" do
      host = "256.0.0.300"
      res = proc {
        Opensips::MI.connect :xmlrpc, {:host => host, :port => 8088}
      }.must_raise SocketError
      res.message.must_match(/#{host}/)
    end

    it "must raise if invalid port" do
      proc {
        Opensips::MI.connect :xmlrpc, {:host => "10.0.0.1", :port => (2**16 + 1)}
      }.must_raise SocketError
      
      proc {
        Opensips::MI.connect :xmlrpc, {:host => "10.0.0.1", :port => 0}
      }.must_raise SocketError
    end

    it "must connect to xmlrpc server" do
      host = "192.168.122.128" 
      port = 8080
      rpc = mock('XMLRPC::Client')
      rpc.stubs(:new_from_uri).
        with("http://#{host}:#{port}/#{Opensips::MI::Transport::Xmlrpc::RPCSEG}",nil,3)
      res = Opensips::MI.connect :xmlrpc, 
                                 :host => host, 
                                 :port => port

      res.respond_to?(:uac_dlg).must_equal true
      
      params = ["aaa","bbb"]
      cmd    = "command"
      rpc.stubs(:call).with(cmd, *params).returns( response_data_cmd_which )
      res.command(cmd, params) #.must_be_instance_of Opensips::MI::Response
    end

  end

end
