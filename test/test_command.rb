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

  end

end
