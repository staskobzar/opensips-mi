# frozen_string_literal: true

include Opensips::MI::Transport

class Subject < Abstract; end

describe Opensips::MI::Transport::Abstract do
  subject { Subject.new }
  context "require implement methods" do
    it "#connect" do
      expect { subject.connect }.to raise_error NotImplementedError
    end
    it "#send(*args)" do
      expect { subject.send("") }.to raise_error NotImplementedError
    end
  end

  describe "#adapter_request" do
    it "with single arg as commad name" do
      expect(subject.adapter_request("ps"))
        .to match(/^{"jsonrpc":"2.0","id":\d+,"method":"ps"}$/)
    end

    it "with command and extra params" do
      expect(subject.adapter_request("ul_sync", "locations"))
        .to match(/^{"jsonrpc":"2.0","id":\d+,"method":"ul_sync","params":\["locations"\]}$/)
      expect(subject.adapter_request("ul_sync", "locations", "alice@pbx.com"))
        .to match(/"params":\["locations","alice@pbx.com"\]/)
      expect(subject.adapter_request("list", "foo", "bar", "xyz", "pbx"))
        .to match(/"params":\["foo","bar","xyz","pbx"\]/)
    end

    it "with command and array" do
      expect(subject.adapter_request("lb_status", %w[1 0]))
        .to match(/"method":"lb_status","params":\["1","0"\]/)
      expect(subject.adapter_request("foo", %w[bar 12 22]))
        .to match(/"method":"foo","params":\["bar","12","22"\]/)
    end

    it "with command as a hash" do
      expect(subject.adapter_request("lb_status", { node: "1", status: "0" }))
        .to match(/"params":{"node":"1","status":"0"}/)
    end
  end

  describe "#adapter_response" do
    it "returns result of jsron-rpc" do
      [
        { input: %({"jsonrpc":"2.0","result":"OK","id":"15173"}), want: { result: "OK" } },
        { input: %({"jsonrpc":"2.0","error":{"code":404,"message":"Table not found"},"id":"31204"}),
          want: { error: { "code" => 404, "message" => "Table not found" } } },
        { input: %({"state":"OK"}), want: { error: { "message" => %(invalid response: {"state":"OK"}) } } },
        { input: "not a json",
          want: { error: { "message" => %(JSON::ParserError: unexpected token at 'not a json') } } }
      ].each do |test|
        test => {input: input, want: want}
        expect(subject.adapter_response(input)).to eql(want)
      end
    end
  end
end
