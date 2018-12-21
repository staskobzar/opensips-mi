include Opensips::MI

describe Response do
  it "must raise if parameter is not Array" do
    expect {Response.new "foo"}.to raise_error InvalidResponseData
  end

  it "must raise if response data id empty array" do
    expect {Response.new Array[]}.to raise_error EmptyResponseData
  end

  it "must raise if invalid response data" do
    expect {Response.new(["invalid param","343",222])}.
      to raise_error InvalidResponseData
  end

  it "must parse successfull response" do
    resp = Response.new ["200 it is OK", "data", ""]
    expect(resp.success).to be_truthy
    expect(resp.code).to be(200)
    expect(resp.message).to match("it is OK")
  end

  it "must parse unsuccessfull response" do
    resp = Response.new ["500 command 'unknown' not available"]
    expect(resp.success).to be_falsey
    expect(resp.code).to be(500)
    expect(resp.message).to match("command 'unknown' not available")
  end

  it "parse ul dump response" do
    res = Response.new(fixture('ul_dump'))
    ul = res.ul_dump
    expect(ul.result["7962"]).not_to be_nil
    expect(ul.result["7962"][0][:callid]).to match("5e7a1e47da91c41c")
  end

  it "process uptime response" do
    res = Response.new [
      "200 OK",
      "Now:: Fri Apr 12 22:04:27 2013",
      "Up since:: Thu Apr 11 21:43:01 2013",
      "Up time:: 87686 [sec]",
      ""
    ]
    resp = res.uptime
    expect(resp.result.uptime).to be(87686)
    expect(resp.result.since.thursday?).to be_truthy
    expect(resp.result.since.hour).to be(21)
    expect(resp.result.since.mon).to be(4)
  end

  it "must fetch cache value" do
    res = Response.new [
      "200 OK",
      "userdid = [18005552211]",
      ""
    ]
    resp= res.cache_fetch
    expect(resp.result.userdid).to match("18005552211")
  end

  it "must return userloc contacts" do
    contacts = ["200 OK",
      "Contact:: <sip:7747@10.132.113.198>;q=;expires=100;flags=0x0;cflags=0x0;socket=<udp:10.130.8.21:5060>;methods=0x1F7F;user_agent=<PolycomSoundStationIP-SSIP_6000-UA/3.3.5.0247_0004f2f18103>",
      "Contact:: <sip:7747@10.130.8.100;line=628f4ffdfa7316e>;q=;expires=3593;flags=0x0;cflags=0x0;socket=<udp:10.130.8.21:5060>;methods=0xFFFFFFFF;user_agent=<Linphone/3.5.2 (eXosip2/3.6.0)>",
      ""]
    response = Response.new contacts
    res = response.ul_show_contact
    expect(res.size).to be(2)
    expect(res.first[:socket]).to match("<udp:10.130.8.21:5060>")
    expect(res.last[:expires]).to match("3593")
  end

  it "must process dialogs list" do
    response = Response.new fixture('dlg_list')
    res = response.dlg_list.result
    expect(res.size).to be(1)
    expect(res["3212:2099935485"][:callid]).to match("1854719653")
  end

  it "must process dr_gw_status response in hash" do
    gw_list = [
      "200 OK",
      "ID:: gw1 IP=212.182.133.202:5060 Enabled=no ",
      "ID:: gw2 IP=213.15.222.97:5060 Enabled=yes",
      "ID:: gw3 IP=200.182.132.201:5060 Enabled=yes",
      "ID:: gw4 IP=200.182.135.204:5060 Enabled=yes",
      "ID:: pstn1 IP=199.18.14.101:5060 Enabled=yes",
      "ID:: pstn2 IP=199.18.14.102:5060 Enabled=no",
      "ID:: pstn3 IP=199.18.12.103:5060 Enabled=yes",
      "ID:: pstn4 IP=199.18.12.104:5060 Enabled=yes",
      ""
    ]
    response = Response.new gw_list
    drgws = response.dr_gw_status
    expect(drgws.result.size).to be(8)
    expect(drgws.result["pstn4"][:ipaddr]).to match("199.18.12.104")
    expect(drgws.result["pstn3"][:port]).to match("5060")
    expect(drgws.result["gw1"][:enabled]).to be_falsey
    expect(drgws.result["gw4"][:enabled]).to be_truthy
  end

  it "must return raw data if dr_gw_status is run with arguments" do
    gw = [ "200 OK", "Enabled:: yes", "" ]
    response = Response.new gw
    drgws = response.dr_gw_status
    expect(drgws.enabled).to be_truthy
  end

  it "result must be empty if command send to dr_gw_status" do 
    response = Response.new [ "200 OK", "" ]
    drgws = response.dr_gw_status
    expect(drgws.result).to be_nil
    expect(drgws.success).to be_truthy
  end
end
