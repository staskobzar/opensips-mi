require 'helper'
include Opensips::MI

describe Command, "commands for transport classes" do
  before do
    @which = response_data_cmd_which
    @data_ok  = ["200 it is OK", "data", ""]
    @data_nok = ["500 command 'unknown' not available"]
  end

  after do
  end

  describe "missing methods" do
    it "must raise if parameter is not Array" do
    end

    it "must send command" do
      #res = Response.new(which)
      #fifo = init_class_fifo
      #pp fifo
    end
  end

end
