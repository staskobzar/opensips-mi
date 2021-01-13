include Opensips::MI

describe Transport do
  context "fifo" do
    it "must raise when using unknown transport method" do
      expect {
        Opensips::MI.connect(:unknown_transport_method,{})
      }.to raise_error NameError
    end

    it "must raise when no fifo_nameInstanceOf.new parameter passed" do
      expect {
        Opensips::MI.connect :fifo, {}
      }.to raise_error ArgumentError
    end

    it "must raise when fifo_name file not exists" do
      allow(File).to receive(:exists?).and_return(false)
      expect {
        Opensips::MI.connect :fifo, :fifo_name => '/file/not/exists'
      }.to raise_error ArgumentError
    end

    it "must raise when fifo_name file is not pipe" do
      allow(File).to receive(:exists?).and_return(true)
      allow(File).to receive(:pipe?).and_return(false)
      expect {
        Opensips::MI.connect :fifo, :fifo_name => '/tmp/opensips_fifo'
      }.to raise_error ArgumentError
    end

    it "must raise if fifo reply directory not exists" do
      allow(Dir).to receive(:exists?).and_return(false)
      expect {
        Opensips::MI.connect :fifo, :fifo_name => '/tmp/opensips_fifo',
        :reply_dir => '/tmp'
      }.to raise_error ArgumentError
    end
  end

  context "datagram" do
    it "must raise if empty host" do
      expect {
        Opensips::MI.connect :datagram, {}
      }.to raise_error ArgumentError
    end

    it "must raise if empty port" do
      expect {
        Opensips::MI.connect :datagram, {:host => "10.10.10.10"}
      }.to raise_error ArgumentError
    end

    it "must raise if invalid host" do
      host = "256.0.0.300"
      expect {
        Opensips::MI.connect :datagram, {:host => host, :port => 8088}
      }.to raise_error(SocketError, /#{host}/)
    end

    it "must raise if invalid port" do
      expect {
        Opensips::MI.connect :datagram, {:host => "10.0.0.1", :port => (2**16 + 1)}
      }.to raise_error SocketError

      expect {
        Opensips::MI.connect :datagram, {:host => "10.0.0.1", :port => 0}
      }.to raise_error SocketError
    end

    it "default timeout is 3 sec" do
      mi=Opensips::MI.connect :datagram, {:host => "10.0.0.1", :port => 8088}
      expect(mi.tout).to be(3)
    end

    it "must set timeout from params" do
      mi=Opensips::MI.connect :datagram, {:host => "10.0.0.1", :port => 8088, :timeout => 15}
      expect(mi.tout).to be(15)
    end

    it "must foo" do
      mi=Opensips::MI.connect :datagram, {:host => "10.0.0.1", :port => 8088, :timeout => 1}
      expect {
        mi.uptime
      }.to raise_error Timeout::Error
    end
  end

  context "xmlrpc" do
    it "must raise if empty host" do
      expect {
        Opensips::MI.connect :xmlrpc, {}
      }.to raise_error ArgumentError
    end

    it "must raise if empty port" do
      expect {
        Opensips::MI.connect :xmlrpc, {:host => "10.10.10.10"}
      }.to raise_error ArgumentError
    end

    it "must raise if invalid host" do
      host = "256.0.0.300"
      expect {
        Opensips::MI.connect :xmlrpc, {:host => host, :port => 8088}
      }.to raise_error(SocketError, /#{host}/)
    end

    it "must raise if invalid port" do
      expect {
        Opensips::MI.connect :xmlrpc, {:host => "10.0.0.1", :port => (2**16 + 1)}
      }.to raise_error SocketError

      expect {
        Opensips::MI.connect :xmlrpc, {:host => "10.0.0.1", :port => 0}
      }.to raise_error SocketError
    end
  end
end
