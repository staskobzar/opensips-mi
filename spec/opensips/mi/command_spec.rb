# frozen_string_literal: true

include Opensips::MI

describe Opensips::MI::Command do
  describe "#command" do
    let(:transp) { Transport::HTTP.new(url: "http://pbx.com") }
    before { allow(transp).to receive(:adapter_response) }

    context "exec pipeline" do
      it "raise error when missing args" do
        expect { Command.new(transp).command }
          .to raise_error ErrorParams
      end

      it "with single argument" do
        expect(transp).to receive(:send).with(/{"jsonrpc":"2.0","id":\d+,"method":"ps"}/)
        Command.new(transp).command("ps")
      end

      it "with multiple arguments" do
        expect(transp).to receive(:send).with(/"method":"lb_status","params":\["1","0"\]/)
        Command.new(transp).command("lb_status", "1", "0")
      end

      it "with hash parameter" do
        expect(transp).to receive(:send).with(/"method":"log_level","params":{"level":4,"pid":987}}/)
        Command.new(transp).command("log_level", { level: 4, pid: 987 })
      end

      it "with array parameter" do
        expect(transp).to receive(:send).with(/"method":"log_level","params":\["6","1235"\]}/)
        Command.new(transp).command("log_level", %w[6 1235])
      end
    end

    context "meta methods" do
      it "without arguments" do
        expect(transp).to receive(:send).with(/{"jsonrpc":"2.0","id":\d+,"method":"ps"}/)
        Command.new(transp).ps
      end

      it "with multiple arguments" do
        expect(transp).to receive(:send).with(/"method":"lb_status","params":\["1","0"\]/)
        Command.new(transp).lb_status("1", "0")
      end

      it "with array parameter" do
        expect(transp).to receive(:send).with(/"method":"foo","params":\["6","5"\]}/)
        Command.new(transp).foo(%w[6 5])
      end

      it "with hash parameter" do
        expect(transp).to receive(:send).with(/"method":"log_level","params":{"level":4,"pid":987}}/)
        Command.new(transp).log_level(level: 4, pid: 987)
      end
    end
  end

  describe "#uac_dlg" do
    let(:transp) do
      transp = double("transp")
      allow(transp).to receive(:send)
      allow(transp).to receive(:adapter_response)
      transp
    end

    it "raised error on missing mandatory headers" do
      cmd = Command.new(transp)
      expect { cmd.uac_dlg("NOTIFY", "sip:alice@pbx.com", nil) }
        .to raise_error ArgumentError
      expect { cmd.uac_dlg("NOTIFY", "sip:alice@pbx.com", {}) }
        .to raise_error ArgumentError
      expect { cmd.uac_dlg("NOTIFY", "sip:alice@pbx.com", { "To" => "sib:bob@pbx.com" }) }
        .to raise_error ArgumentError
      expect { cmd.uac_dlg("NOTIFY", "sip:alice@pbx.com", { from: "sib:bob@pbx.com" }) }
        .to raise_error ArgumentError
    end

    it "sends command" do
      cmd = Command.new(transp)

      expect(transp).to receive(:adapter_request)
        .with("t_uac_dlg",
              ["NOTIFY", "sip:alice@pbx.com", ".", ".",
               "To: sib:bob@pbx.com\r\nFrom: sip:alice@pbx.com\r\n\r\n"])
      cmd.uac_dlg("NOTIFY", "sip:alice@pbx.com", { "To" => "sib:bob@pbx.com", "From" => "sip:alice@pbx.com" })
    end

    context "#event_notify" do
      it "raise on invalid event" do
        cmd = Command.new(transp)
        expect(transp).to receive(:adapter_request)
          .with("t_uac_dlg",
                ["NOTIFY", "sip:alice@sip.pbx", ".", ".",
                 "From: sip:bob@sip.pbx\r\nTo: <sip:alice@sip.pbx>\r\nEvent: check-sync\r\n\r\n"])
        cmd.event_notify("sip:alice@sip.pbx", "check-sync", { "From" => "sip:bob@sip.pbx" })
      end
    end

    context "#mwi_update" do
      it "raise on invalid event" do
        cmd = Command.new(transp)
        expect(transp).to receive(:adapter_request)
          .with("t_uac_dlg", array_including("NOTIFY", "sip:bob@sip.pbx"))
        cmd.mwi_update("sip:bob@sip.pbx", "sip:*97@sip.pbx", 5)
      end
    end
  end
end
