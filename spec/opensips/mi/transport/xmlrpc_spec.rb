# frozen_string_literal: true

include Opensips::MI::Transport

describe Opensips::MI::Transport::Xmlrpc do
  describe "#initialize" do
    it "fails on wrong address" do
      expect { Xmlrpc.new("localhost") }.to raise_error Opensips::MI::ErrorParams
      expect { Xmlrpc.new(foo: "localhost") }.to raise_error Opensips::MI::ErrorParams
      expect { Xmlrpc.new(timeout: 5) }.to raise_error Opensips::MI::ErrorParams
      expect { Xmlrpc.new(url: "hp://::") }.to raise_error Opensips::MI::ErrorParams
    end
    it "success on good params" do
      expect { Xmlrpc.new(url: "http://localhost:8000/rpc") }.not_to raise_error
      expect { Xmlrpc.new(url: "http://127.0.0.1/rpc", timeout: 5) }.not_to raise_error
    end
  end

  describe "#send" do
    let(:uri) { "http://sip.pbx.com:8800/mi" }
    let(:resp_xml_error) do
      %(<?xml version="1.0" encoding="UTF-8"?><methodResponse><fault><value>
<struct><member><name>faultCode</name><value><int>-32602</int></value></member>
<member><name>faultString</name><value><string>server error. invalid method parameters</string></value>
</member></struct></value></fault></methodResponse>)
    end
    let(:resp_body) do
      %(<?xml version="1.0" encoding="UTF-8"?><methodResponse><params><param><value><struct>
<member><name>Now</name><value><string>Tue Aug  8 15:06:20 2023</string></value></member>
<member><name>Up time</name><value><string>6001 [sec]</string></value></member>
</struct></value> </param></params> </methodResponse>)
    end

    it "successfull request with correct content-type header" do
      stub_request(:post, uri)
        .with(headers: { "Content-Type": "text/xml; charset=utf-8" })
        .to_return(status: 200, body: resp_body)
      mi = Xmlrpc.new(url: uri)
      resp = mi.send("ps")
      expect(resp["Now"]).to eq "Tue Aug  8 15:06:20 2023"
    end

    it "raises error on http error" do
      stub_request(:post, uri)
        .to_return(status: [400, "Bad Request"])
      mi = Xmlrpc.new(url: uri)
      expect { mi.send("foo", "bar") }.to raise_error(Opensips::MI::ErrorHTTPReq, /Bad Request/)
    end

    it "raises error on http request timeout" do
      stub_request(:post, uri).to_timeout
      mi = Xmlrpc.new(url: uri, timeout: 0.5)
      expect { mi.send("ps") }.to raise_error(Opensips::MI::ErrorHTTPReq, /execution expired/)
    end

    it "handles exception on xmlrpc error" do
      stub_request(:post, uri)
        .to_return(status: 200, body: resp_xml_error)
      mi = Xmlrpc.new(url: uri)
      expect { mi.send("foo") }.not_to raise_error
    end

    it "converts exception on xmlrpc error" do
      stub_request(:post, uri)
        .to_return(status: 200, body: resp_xml_error)
      mi = Xmlrpc.new(url: uri)
      resp = mi.send("foo")
      expect(resp).to have_key(:error)
      expect(resp[:error]["message"]).to eq "server error. invalid method parameters"
    end
  end

  describe "#adapter_request" do
    let(:mi) { Xmlrpc.new(url: "http://pbx.com/rpc") }
    it "handle single argument" do
      expect(mi.adapter_request("ps")).to eq ["ps"]
    end
    it "handle multiple argument" do
      expect(mi.adapter_request("lb_status", "1", "0")).to eq %w[lb_status 1 0]
    end
    it "handle multiple argument with array" do
      expect(mi.adapter_request("lb_status", %w[1 0])).to eq %w[lb_status 1 0]
    end
    it "handle multiple argument with hash" do
      expect(mi.adapter_request("lb_status", { node: "1", status: "0" })).to eq %w[lb_status 1 0]
    end
  end

  describe "#adapter_response" do
    let(:mi) { Xmlrpc.new(url: "http://pbx.com/rpc") }
    it "overloads parent method with result" do
      input = { "Now" => "Wed Aug  9 07:36:22 2023", "Up since" => "Tue Aug  8 13:26:19 2023",
                "Up time" => "65403 [sec]" }

      resp = mi.adapter_response(input)
      expect(resp).to have_key(:result)
      expect(resp[:result]["Now"]).to eq "Wed Aug  9 07:36:22 2023"
      expect(resp[:result]["Up since"]).to eq "Tue Aug  8 13:26:19 2023"
      expect(resp[:result]["Up time"]).to eq "65403 [sec]"
    end

    it "handles xmlrpc error response" do
      err = { error: { "message" => "server error. invalid method parameters" } }
      resp = mi.adapter_response(err)
      expect(resp).to have_key(:error)
      expect(resp[:error]["message"]).to eq "server error. invalid method parameters"
    end
  end
end
