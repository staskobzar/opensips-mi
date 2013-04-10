require 'helper'
include Opensips::MI

describe Response, "response class" do
  before do
    @which = response_data_cmd_which
    @data_ok  = ["200 it is OK", "data", ""]
    @data_nok = ["500 command 'unknown' not available"]
  end

  after do
  end

  describe "processing response" do
    it "must raise if parameter is not Array" do
      proc {
        Response.new "String"
      }.must_raise InvalidResponseData
    end

    it "must raise if response data id empty array" do
      proc {
        Response.new Array[]
      }.must_raise EmptyResponseData
    end

    it "must return Response class" do
      r = Response.new(@data_ok)
      r.must_be_instance_of Response
    end

    it "must raise if invalid response data" do
      proc {
        Response.new(["invalid param","343",222])
      }.must_raise InvalidResponseData
    end

    it "must parse successfull response" do
      r = Response.new(@data_ok)
      r.success.must_equal true
      r.code.must_equal 200
      r.message.must_equal "it is OK"
    end

    it "must parse unsuccessfull response" do
      r = Response.new(@data_nok)
      r.success.must_equal false
      r.code.must_equal 500
      r.message.must_equal "command 'unknown' not available"
    end

    it "parse ul dump response" do
      res = Response.new(response_uldump)
      ul = res.ul_dump
      ul["7962"].wont_equal nil
      ul["7962"]['Callid'].must_equal "5e7a1e47da91c41c"
      
    end
    
  end

end
