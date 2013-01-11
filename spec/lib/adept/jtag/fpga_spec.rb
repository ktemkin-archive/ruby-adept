
require 'adept/jtag'

include Adept

#
# Tests for the JTAGDevice base module.
#
#
describe JTAG::FPGA do

  let(:device)  { JTAG::FPGA.new("\xA2\xC2\xA0\x93", mock(JTAG::Connection), 2, 8)}

  describe "#verify_idcode" do

    it "should send the Xilinx IDCode instruction" do
      
      #Set up the device to recieve a valid IDCode.
      device.stub!(:receive_data).and_return("\x93\xa0\xc2\xa2")
      device.stub!(:run_test)
      device.should_receive(:instruction=).with(:idcode)

      device.verify_idcode
    end

    it "should throw an error when the FPGA returns an IDcode other than the one with which the device was created" do

      #Set up the device to recieve a invalid IDCode.
      device.stub!(:receive_data).and_return("\x00\xa0\xc2\xa2")
      device.stub!(:run_test)
      device.should_receive(:instruction=).with(:idcode)

      expect { device.verify_idcode }.to raise_error(JTAG::Error)

    end

    it "should not throw an error when the FPGA and internal IDcode match" do

     #Set up the device to recieve a invalid IDCode.
      device.stub!(:receive_data).and_return("\x93\xa0\xc2\xa2")
      device.stub!(:run_test)
      device.should_receive(:instruction=).with(:idcode)

      expect { device.verify_idcode }.to_not raise_error(JTAG::Error)

    end

    describe "online tests", :online => true do

      before :all do
        @real_board = Adept::Device.by_name('Basys2')
        @real_connection = JTAG::Connection.new(@real_board, 0)
        @real_device = @real_connection.connected_devices.first
      end

      after :all do
        @real_connection.close
        @real_board.close
      end

      it "should be able to verify the IDcode produced by a Basys2 board" do
        expect { @real_device.verify_idcode }.to_not raise_error
      end

      it "should be able to detect the usercode of a design" do
        @real_device.usercode.should == "\xFF\xFF\xFF\xFF"
      end

    end
  end
end
