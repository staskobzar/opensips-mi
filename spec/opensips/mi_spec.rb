# frozen_string_literal: true

describe Opensips::MI do
  it "raises on unknow transport" do
    expect { Opensips::MI.connect(:foo) }
      .to raise_error Opensips::MI::Error
  end

  context "#command" do
    it "via datagram" do
      srv = UDPSocket.new
      srv.bind("127.0.0.1", 50_000)
      msg = ""
      thr = Thread.new do
        msg, _, port, host, = srv.recvfrom(1500).flatten
        srv.send(%({"jsonrpc":"2.0","result":"OK","id":"15173"}), 0, host, port)
      end
      host, port = srv.local_address.getnameinfo

      mi = Opensips::MI.connect(:datagram, host: host, port: port, timeout: 1)

      resp = mi.lb_status("1", "0")
      expect(resp).to have_key(:result)
      expect(resp[:result]).to eql "OK"
      expect(msg).to match(/"method":"lb_status","params":\["1","0"\]}/)

      thr.exit
      srv.close
    end

    it "via http" do
      res_body = %({"id": 10,"jsonrpc": "2.0","result":{"Processes":[{"ID":0,"PID":513617,"Type":"attendant"},) +
                 %({"ID":1,"PID":513618,"Type":"RabbitMQ sender"}]}})
      uri = "http://pbx.com/mi"
      stub_request(:post, uri)
        .to_return(status: 200, body: res_body)

      mi = Opensips::MI.connect(:http, url: uri, timeout: 1)
      resp = mi.ps

      expect(resp).to have_key(:result)
      procs = resp[:result]["Processes"]
      expect(procs.length).to be 2
      expect(procs[0]["PID"]).to be 513_617
    end

    it "via xmlrpc" do
      resp_body = %(<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct>
<member><name>Now</name><value><string>Tue Aug  8 15:06:20 2023</string></value></member>
<member><name>Up time</name><value><string>6001 [sec]</string></value></member>
</struct></value> </param></params> </methodResponse>)
      uri = "http://pbx.com/mi"
      stub_request(:post, uri)
        .with(body: %r{<methodName>lb_list</methodName>})
        .to_return(status: 200, body: resp_body)

      mi = Opensips::MI.connect(:xmlrpc, url: uri, timeout: 1)
      resp = mi.lb_list

      expect(resp).to have_key(:result)
      expect(resp[:result]["Now"]).to eql "Tue Aug  8 15:06:20 2023"
    end
  end
end
