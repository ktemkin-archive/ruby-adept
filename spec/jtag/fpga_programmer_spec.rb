
require 'adept/jtag/fpga_programmer'

#
# Tests of the FPGA programmer.
#
describe FPGAProgrammer do

  before :all do
    @device = Device.by_name('Basys2')
    @jtag = JTAGConnection.new(@device)
  end

  after :all do
    @jtag.close
    @device.close
  end

  before :each do

    #Clear any expectations held by the low-level JTAG library.
    LowLevel::JTAG::rspec_reset

    #Place the JTAG test access port into the reset state.
    @jtag.reset_target

  end

  #
  # Read IDCodes from each of the attached devices.
  #
  describe "#idcodes" do

  end


end
