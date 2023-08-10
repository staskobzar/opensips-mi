# frozen_string_literal: true

require "socket"

include Opensips::MI::Transport

describe Opensips::MI::Transport::Datagram do
  describe "#initialize" do
    it "fails on wrong address" do
      expect { Datagram.new("localhost") }.to raise_error Opensips::MI::ErrorParams
      expect { Datagram.new(foo: "localhost") }.to raise_error Opensips::MI::ErrorParams
      expect { Datagram.new(host: "localhost") }.to raise_error Opensips::MI::ErrorParams
      expect { Datagram.new(port: 1929) }.to raise_error Opensips::MI::ErrorParams
      expect { Datagram.new(host: "localhost", port: 0) }.to raise_error Opensips::MI::ErrorParams
      expect { Datagram.new(host: "localhost", port: 9_999_999) }.to raise_error Opensips::MI::ErrorParams
    end
  end

  describe "#send" do
    it "fails on closed port" do
      srv = UDPSocket.new
      srv.bind("localhost", 0)
      host, port = srv.local_address.getnameinfo
      srv.close
      transp = Datagram.new(host: host, port: port, timeout: 0.5)

      expect { transp.send("{jsonrpc: 2}") }.to raise_error Errno::ECONNREFUSED
    end

    it "fails on timeout" do
      srv = UDPSocket.new
      srv.bind("127.0.0.1", 0)
      host, port = srv.local_address.getnameinfo
      transp = Datagram.new(host: host, port: port, timeout: 0.5)
      expect { transp.send("timeout") }.to raise_error Opensips::MI::ErrorSendTimeout
      srv.close
    end

    it "send and receive response" do
      srv = UDPSocket.new
      srv.bind("127.0.0.1", 0)
      thr = Thread.new do
        _, _, port, host, = srv.recvfrom(1500).flatten
        srv.send("OK", 0, host, port)
      end
      host, port = srv.local_address.getnameinfo
      transp = Datagram.new(host: host, port: port, timeout: 1)
      expect(transp.send("{jsonrpc: 2.0}")).to eq "OK"

      thr.exit
      srv.close
    end
  end
end
