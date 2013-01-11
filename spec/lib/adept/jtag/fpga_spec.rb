
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

      lambda { device.verify_idcode }.should raise_error(JTAG::Error)

    end

    it "should not throw an error when the FPGA and internal IDcode match" do

     #Set up the device to recieve a invalid IDCode.
      device.stub!(:receive_data).and_return("\x93\xa0\xc2\xa2")
      device.stub!(:run_test)
      device.should_receive(:instruction=).with(:idcode)

      lambda { device.verify_idcode }.should_not raise_error(JTAG::Error)

    end

    it "should be able to verify the IDcode produced by a Basys2 board", :online => true do

      puts
      class << LowLevel::JTAG

        alias_method :transmit_old, :transmit
        alias_method :receive_old, :receive
        alias_method :tick_old, :tick

        def transmit(*a); with_hook(__method__, *a); end
        def tick(*a); with_hook(__method__, *a); end


        def receive(*a) 
          with_hook(__method__, *a)
        end

        def with_hook(function, *a)

          retval = send(function.to_s + "_old", *a)

          tms = a[1].respond_to?(:unpack) ? a[1].unpack("B*") : a[1]
          tdi = a[2].respond_to?(:unpack) ? a[2].unpack("B*") : a[2]
          retval_print = retval.respond_to?(:unpack) ? retval.unpack("B*") : retval
          
          puts "Transmitting with #{function},\t arguments were\t TMS:#{tms}\t TDI: #{tdi}\t bit count #{a[3]} => #{retval_print}"

          return retval
        end

      end

      #Create a connection to the Basys2 board...
      real_board = Adept::Device.by_name('Basys2')
      real_connection = JTAG::Connection.new(real_board, 0)
      real_device = real_connection.connected_devices.first

      class << real_connection 

        def transmit_in_state(state_before, value, bit_count, state_after=nil, pad_with=false, pad_before=0, pad_after=0)
          puts "Transmitting #{bit_count} bits of #{value.inspect} in state #{state_before}; padding with #{pad_before} #{pad_with}'s before, and #{pad_after} after, and then moving to #{state_after}."
          super
        end
  

      end

      LowLevel::JTAG::set_speed(real_board.handle, 100)

      begin
        lambda { real_device.verify_idcode }.should_not raise_error
      ensure
        real_connection.close
        real_board.close
      end

    end

  end
  

end
