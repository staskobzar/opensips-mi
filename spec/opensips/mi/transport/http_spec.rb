# frozen_string_literal: true

include Opensips::MI::Transport

describe Opensips::MI::Transport::HTTP do
  describe "#initialize" do
    it "fails on wrong address" do
      expect { HTTP.new("localhost") }.to raise_error Opensips::MI::ErrorParams
      expect { HTTP.new(foo: "localhost") }.to raise_error Opensips::MI::ErrorParams
      expect { HTTP.new(timeout: 5) }.to raise_error Opensips::MI::ErrorParams
      expect { HTTP.new(url: "hp://::") }.to raise_error Opensips::MI::ErrorParams
    end
    it "success on good params" do
      expect { HTTP.new(url: "http://localhost:8000/mi") }.not_to raise_error
      expect { HTTP.new(url: "http://127.0.0.1/mi", timeout: 5) }.not_to raise_error
    end
  end

  describe "#connect" do
    it "starts http session" do
      mi = HTTP.new(url: "http://localhost:8080/mi")
      expect { mi.connect }.not_to raise_error
    end
  end

  describe "#send" do
    let(:uri) { "http://sip.pbx.com:8800/mi" }
    let(:req_body) { %({"jsonrpc":"2.0","method":"FOO"}) }
    let(:res_body) { %({"jsonrpc":"2.0","result":"OK"}) }
    let(:headers) { { "Content-Type": "application/json" } }

    it "successfull request with correct content-type header" do
      stub_request(:post, uri)
        .with(body: req_body, headers: headers)
        .to_return(status: 200, body: res_body)
      mi = HTTP.new(url: uri)
      mi.connect
      resp = mi.send(req_body)
      expect(resp).to eq res_body
    end

    it "raises error on http error" do
      stub_request(:post, uri)
        .with(body: req_body, headers: headers)
        .to_return(status: [400, "Bad Request"])
      mi = HTTP.new(url: uri)
      mi.connect
      expect { mi.send(req_body) }.to raise_error(Opensips::MI::ErrorHTTPReq, /Bad Request/)
    end

    it "raises error on http request timeout" do
      stub_request(:post, uri).to_timeout
      mi = HTTP.new(url: uri, timeout: 0.5)
      mi.connect
      expect { mi.send(req_body) }.to raise_error Net::OpenTimeout
    end
  end
end
