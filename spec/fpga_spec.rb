
require 'adept/jtag'

include Adept

#
# Tests for the JTAGDevice base module.
#
#
describe JTAG::FPGA do

  let(:device)  { FPGA.new("\xA1\xC1\xA0\x93", mock(JTAG::Connection), 1, 8)}

  describe "#verify_idcode" do

    it "should send the Xilinx IDCode instruction" do
      
      #Set up the device to recieve a valid IDCode.
      device.stub!(:receive_data).and_return("\x93\xa0\xc1\xa1")
      device.should_receive(:instruction=).with(:idcode)

      device.verify_idcode
    end

    it "should throw an error when the FPGA returns an IDcode other than the one with which the device was created" do

      #Set up the device to recieve a invalid IDCode.
      device.stub!(:receive_data).and_return("\x00\xa0\xc1\xa1")
      device.should_receive(:instruction=).with(:idcode)

      lambda { device.verify_idcode }.should raise_error(JTAG::Error)

    end

    it "should not throw an error when the FPGA and internal IDcode match" do

     #Set up the device to recieve a invalid IDCode.
      device.stub!(:receive_data).and_return("\x93\xa0\xc1\xa1")
      device.should_receive(:instruction=).with(:idcode)

      lambda { device.verify_idcode }.should_not raise_error(JTAG::Error)

    end

    it "should be able to verify the IDcode produced by a Basys2 board", :online => true do

      #Create a connection to the Basys2 board...
      real_board = Adept::Device.by_name('Basys2')
      real_connection = JTAG::Connection.new(real_board, 0)
      real_device = real_connection.connected_devices.first

      begin
        lambda { real_device.verify_idcode }.should_not raise_error(JTAG::Error)
      ensure
        real_connection.close
        real_board.close
      end

    end

  end
  

end
