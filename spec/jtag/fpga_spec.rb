#
# These tests assume _one_ single connected Basys2 board!
#

require 'adept'
require 'adept/jtag/fpga'

#Pull the relevant modules into the main namespace, for convenience.
include Adept
include Adept::JTAG

describe FPGA do

  it "should indicatesupport the XCS250E-CP132" do
    FPGA.supports?("\xD5\x04\x50\x93").should be_true
  end

end
