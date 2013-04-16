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
      ul.result["7962"].wont_equal nil
      ul.result["7962"]['Callid'].must_equal "5e7a1e47da91c41c"
    end

    it "process uptime response" do
      res = Response.new [
        "200 OK",
        "Now:: Fri Apr 12 22:04:27 2013",
        "Up since:: Thu Apr 11 21:43:01 2013",
        "Up time:: 87686 [sec]",
        ""
      ]
      response = res.uptime
      response.result.uptime.must_equal 87686
      response.result.since.thursday?.must_equal true
      response.result.since.hour.must_equal 21
      response.result.since.mon.must_equal 4
    end

    it "must fetch cache value" do
      res = Response.new [
        "200 OK",
        "userdid = [18005552211]",
        ""
      ]
      response = res.cache_fetch
      response.result.userdid.must_equal "18005552211"
    end
    
    it "must return userloc contacts" do
      response = Response.new response_contacts
      res = response.ul_show_contact.result
      res.must_be_instance_of Array
      res.size.must_equal 2
      res.first[:socket].must_equal "<udp:10.130.8.21:5060>"
      res.last[:expires].must_equal "3593"
    end

    it "must process dialogs list" do
      response = Response.new response_dlg_list
      res = response.dlg_list.result
      res.size.must_equal 1
      res["3212:2099935485"][:callid].must_equal "1854719653"
    end
  end

end
