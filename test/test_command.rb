require 'helper'
include Opensips::MI

describe Command, "commands for transport classes" do
  before do
  end

  after do
  end

  describe "missing methods" do
    it "must raise if parameter is not Array" do
      mi = init_class_fifo
      mi.expects(:command).with('which').returns(mock(:data => ['meth1', 'meth2']))
      proc {
        mi.unknown_command
      }.must_raise NoMethodError
    end

    it "must raise when missing basic mandatory headers" do
      mi = init_class_fifo
      ret = proc {
        mi.uac_dlg  "NOTIFY", 
                    "sip:alice@wanderland.com", 
                    {"From" => "<sip:opensips@sipproxy.com>"}
      }.must_raise ArgumentError
      ret.message.must_match(/header To/)

    end

    it "must raise when missing body mandatory headers" do
      mi = init_class_fifo
      ret = proc {
        mi.uac_dlg  "NOTIFY", 
                    "sip:alice@wanderland.com", 
                    {"From" => "<sip:opensips>", "To" => "<sip:bob>", "content-type" => "xml"},
                    ?., ?., "<body>Hello</body>"
      }.must_raise ArgumentError
      ret.message.must_match(/header Content-length/)
    end

    it "must have good parameters" do
      mi = init_class_fifo
      mi.expects(:command).with('t_uac_dlg', [
                                "NOTIFY",
                                "sip:alice@wanderland.com", 
                                ".",
                                ".",
                                %Q/"From: <sip:opensips@sipproxy.com> \r\nTo: <sip:alice@wanderland.com> \r\n"/
                               ])
      mi.uac_dlg  "NOTIFY", 
                  "sip:alice@wanderland.com", 
                  {
                    "From"  => "<sip:opensips@sipproxy.com>",
                    "To"    => "<sip:alice@wanderland.com>"
                  }

    end

    it "must raise when invalid event" do
      mi = init_class_fifo
      event = :unknown_event
      res = proc {
        mi.event_notify "sip:alice@proxy.com", event
      }.must_raise ArgumentError
      res.message.must_match(/#{event.to_s}/)
    end

    it "must send notify event" do
      mi = init_class_fifo
      tag = "123456"
      uri = "sip:alice@wanderland.com" 
      SecureRandom.stubs(:hex).returns(tag)
      mi.expects(:uac_dlg).with("NOTIFY",
                                uri,
                                {
                                  "To"    => "<#{uri}>",
                                  "From"  => "<#{uri}>;tag=#{tag}",
                                  "Event" => "check-sync"
                                } 
                               )
      mi.event_notify uri, :polycom_check_cfg
    end

  end
end
