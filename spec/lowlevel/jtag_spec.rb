#
# These tests assume _one_ single connected Basys2 board!
#

require 'adept'
require 'adept/lowlevel'

#Pull the relevant modules into the main namespace, for convenience.
include Adept

#
# Specification for the low-level Adept JTAG interface.
# These tests assume _only_ one connected Basys2 board!
#
describe LowLevel::JTAG do

  #Before each test, create a connection to a Basys board
  before :each do
    @device = Device.by_name('Basys2')
  end

  #Close the Basys connection after each test.
  after :each do
    @device.close
  end


  it "should detect that a Basys2 board supports JTAG" do
    LowLevel::JTAG.supported?(@device).should be_true
  end

  it "should detect exactly one JTAG port on a Basys2 board" do 
    LowLevel::JTAG.port_count(@device).should == 1
  end

  it "should detect that a Basys2 board supports set the JTAG connection speed" do
    support = LowLevel::JTAG.supported_calls(@device, 0)
    support[:set_speed].should be_true
  end

  it "should detect that a Basys2 board can't set the individual JTAG pins" do
    support = LowLevel::JTAG.supported_calls(@device, 0)
    support[:set_pins].should be_false
  end

  it "should be able to open a JTAG connection to the FPGA on a Basys 2" do
    LowLevel::JTAG.EnableEx(@device.handle, 0)
  end

  it "should be able to _close_ a JTAG connection" do
    LowLevel::JTAG.EnableEx(@device.handle, 0)
    LowLevel::JTAG.Disable(@device.handle)
  end

  



end
