# frozen_string_literal: true

include Opensips::MI::Transport

describe Opensips::MI::Transport::Fifo do
  describe "#initialize" do
    it "fails on missing file param" do
      expect { Fifo.new("") }.to raise_error Opensips::MI::ErrorParams
      expect { Fifo.new(foo: "bar") }.to raise_error Opensips::MI::ErrorParams
    end

    it "successfully initialize" do
      expect { Fifo.new(fifo_name: mock_fifo_file) }
        .not_to raise_error

      expect { Fifo.new(fifo_name: mock_fifo_file, timeout: 2) }
        .not_to raise_error

      expect { Fifo.new(timeout: 3, fifo_name: mock_fifo_file, reply_dir: "/tmp/foo/bar") }
        .not_to raise_error
    end
  end

  describe "#send" do
    it "timeout on r/w fifo" do
      fifo_file = mock_fifo_file
      mi = Fifo.new(fifo_name: fifo_file, timeout: 0.1)
      expect { mi.send(%({"jsonrpc":"2.0","id":123,"method":"ps"})) }
        .to raise_error Opensips::MI::ErrorSendTimeout
    end

    it "writes command and reads response" do
      fifo_file = mock_fifo_file
      Thread.new do
        fifo_rd = IO.open(IO.sysopen(fifo_file, Fcntl::O_RDONLY))
        sleep(0.1) # ensure not block file before main send method
        cmd = fifo_rd.read_nonblock(1500)
        _, reply_file, = cmd.split(":", 3)
        path = File.join("/tmp", reply_file)
        File.write(path, %({"jsonrpc":"2.0","result":"OK","id":"151"}))
      end
      mi = Fifo.new(fifo_name: fifo_file, timeout: 1)
      expect(mi.send(%({"jsonrpc":"2.0","id":123,"method":"ps"})))
        .to match(/"jsonrpc":"2.0","result":"OK"/)
    end
  end
end
