#
# These tests assume _one_ single connected Basys2 board!
#

require 'adept'
require 'adept/low_level'

#Pull the relevant modules into the main namespace, for convenience.
include Adept

#
# Specification for the low-level Adept JTAG interface.
# These tests assume _only_ one connected Basys2 board!
#
describe LowLevel::JTAG do

  #
  # Tests which do not require a connected Basys2 board.
  #
  describe "offline functionality" do

    describe ".interleave_tms_tdi_byte_pairs" do

      it "should be able to interleave a single byte of TMS/TDI data" do

        #Since we're testing a private method, test from inside of the module.
        LowLevel::JTAG.module_eval do 

          #Attempt to interleave the bytes. Note the little endian byte ordering.
          tms, tdi = 0b1010_1011, 0b1100_1101 
          LowLevel::JTAG.interleave_tms_tdi_byte_pair(tms, tdi).should == [0b1101_1011, 0b1101_1000]

        end

      end

    end

    describe ".interlace_tms_tdi_byte_pairs" do

      it "should be able to interleave two arrays of bytes into a single string" do


        #Since we're testing a private method, test from inside of the module.
        LowLevel::JTAG.module_eval do 

          tms = [0b1010_1011, 0b1111_0000]
          tdi = [0b1100_1101, 0b0000_1111]

          string = LowLevel::JTAG.interleave_tms_tdi_bytes(tms, tdi)
          string.should == [0b1101_1011, 0b1101_1000, 0b0101_0101, 0b1010_1010].pack('C*').force_encoding('UTF-8')

        end

      end

    end

  end

  #
  # Tests which require a connectd Basys2-250K board.
  # 
  describe "online functionality" do

    #Before each test, create a connection to a Basys board
    before :each do
      @device = Adept::Device.by_name('Basys2')
    end

    #Close the Basys connection after each test.
    after :each do
      @device.close
    end

    describe "pre-connection tests" do

      it "should detect that a Basys2 board supports JTAG" do
        LowLevel::JTAG.supported?(@device.handle).should be_true
      end

      it "should detect exactly one JTAG port on a Basys2 board" do 
        LowLevel::JTAG.port_count(@device.handle).should == 1
      end

      it "should detect that a Basys2 board supports set the JTAG connection speed" do
        support = LowLevel::JTAG.supported_calls(@device.handle, 0)
        support[:set_speed].should be_true
      end

      it "should detect that a Basys2 board can't set the individual JTAG pins" do
        support = LowLevel::JTAG.supported_calls(@device.handle, 0)
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

    describe "post-connection tests" do

      #Create a new JTAG connection before each test.
      before :each do
        LowLevel::JTAG.EnableEx(@device.handle, 0)
      end

      #Disconnect from the JTAG device after each test.
      after :each do
        LowLevel::JTAG.Disable(@device.handle)
      end

      #
      # To test each of the JTAG features below, we request that the devices in the scan chain
      # identify themselves.
      # 
    
      IDCode_Basys2_250K = "\xD5\x04\x50\x93"
      IDCode_Platform_Flash = "\x11\xC1\xA0\x93"

      it "should be able to send/recieve using interleaved byte strings" do

        #Request that each of the devices identify themselves.
        sequence = "\xAA\x22\x00"
       
        #Send the command to the device...
        LowLevel::JTAG.transmit_interleave(@device.handle, sequence, 9)

        #And shift in zeroes, simultaneously recieving the device's ID codes.
        response = LowLevel::JTAG.transmit_interleave(@device.handle, "\x00" * 16, 64)

        #Check for the correct ID codes.
        response.reverse.should == IDCode_Platform_Flash + IDCode_Basys2_250K

      end


      it "should be able to send/recieve using interleaved arrays of bytes" do

        #Request that each of the devices identify themselves.
        sequence = [0xAA, 0x22, 0x00] # 1010_1010, 0010_0010, 0000_0000; TMS = 1111 0101
       
        #Send the command to the device...
        LowLevel::JTAG.transmit_interleave(@device.handle, sequence, 9)

        #And shift in zeroes, simultaneously recieving the device's ID codes.
        response = LowLevel::JTAG.transmit_interleave(@device.handle, "\x00" * 16, 64)

        #Check for the correct ID codes.
        response.reverse.should == IDCode_Platform_Flash + IDCode_Basys2_250K

      end

      it "should be able to send/recieve using linear arrays of bytes" do

        #Request that each of the devices identify themselves.
        #tms = [0x5F, 0x00] #1010 1010 =  1111 0101 ; 1010 1111
        tdi = [0x00, 0x00]

        tms = [0x09, 0x00]

        #Send the command to the device...
        LowLevel::JTAG.transmit(@device.handle, tms, tdi, 6)

        #And shift in zeroes, simultaneously recieving the device's ID codes.
        response = LowLevel::JTAG.transmit(@device.handle, "\x00" * 8, "\x00" * 8, 64)

        #Check for the correct ID codes.
        response.reverse.should == IDCode_Platform_Flash + IDCode_Basys2_250K

      end

      it "should be able to accept more optimized transmit/recieve functions " do

        #Request that each of the devices identify themselves.
        LowLevel::JTAG.transmit(@device.handle, [0x09], false, 6)

        #Recieve the device's ID codes.
        response = LowLevel::JTAG.receive(@device.handle, false, false, 64)

        #Check for the correct ID codes.
        response.reverse.should == IDCode_Platform_Flash + IDCode_Basys2_250K

      end

      it "should be able to set the speed of a JTAG connection" do
        LowLevel::JTAG::set_speed(@device.handle, 62500).should == 62500
      end

      it "should be able to read the speed of a JTAG connection" do
        actual_speed = LowLevel::JTAG::set_speed(@device.handle, 62500)
        LowLevel::JTAG::get_speed(@device.handle).should == actual_speed
      end


    end
  end
end
