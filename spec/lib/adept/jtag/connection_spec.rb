require 'adept'
require 'adept/jtag/tap_states'

#Pull the relevant modules into the main namespace, for convenience.
include Adept
include JTAG::TAPStates

#
# Tests for the basic JTAG test connection.
#
describe JTAG::Connection do

  PathToShiftIR = ["01100".reverse.to_i(2)]
  PathToShiftDR = ["0100".reverse.to_i(2)]

  before :each do

    #Stub over the core low-level methods, allowing us to test without a real device.
    LowLevel::JTAG::stub!(:EnableEx => nil, :transmit_mode_select => "\x00", :transmit_data => "\x00", :transmit_constants => "\x00", :tick => nil, :receive => "\x00")

    #Create a new mock adept device.
    @device = mock(Adept::Device)
    @device.stub!(:handle).and_return(1)

    #Establish a new JTAG Connection...
    @jtag = JTAG::Connection.new(@device)

    #And place the device into its "reset" state.
    @jtag.reset_target

  end

  describe "#path_to_state" do

    it "should be able to correctly idenitfy the path to any given state" do

      @jtag.instance_eval do

        #Path from reset to data states.
        path_to_state(SelectDR).should == "01"
        path_to_state(ShiftDR).should  == "0100"
        path_to_state(Exit1DR).should  == "0101"
        path_to_state(PauseDR).should  == "01010"
        path_to_state(UpdateDR).should == "01011"

        #Path from reset to instruction states.
        path_to_state(SelectIR).should == "011"
        path_to_state(ShiftIR).should  == "01100"
        path_to_state(Exit1IR).should  == "01101"
        path_to_state(PauseIR).should  == "011010"
        path_to_state(UpdateIR).should == "011011"

        #Paths from Exit1DR
        @tap_state = Exit1DR
        path_to_state(Exit1IR).should == "11101"

      end

    end
  end

  #
  # TAP State Setter
  #
  describe "#tap_state=" do

    it "should ask the target device to move to the appropriate state" do
      #Ensure that our virtual target is placed into the ShiftIR state.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftIR, false, 5, false)
      @jtag.tap_state = ShiftIR
    end

    it "should adjust the internal state" do
      LowLevel::JTAG::stub!(:transmit_mode_select)
      @jtag.tap_state = ShiftIR
      @jtag.tap_state.should == ShiftIR
    end

  end

  #
  # Transmit TAP instruction
  #
  describe "#transmit_instruction" do

    it "should move the target into the ShiftIR state before transmission" do

      #Ensure that our virtual target is placed into the ShiftIR state _prior_ to transmission.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftIR, false, 5, false).ordered
      LowLevel::JTAG::should_receive(:transmit_data).ordered
      @jtag.transmit_instruction([0x09], 6)

    end

    it "should transmit the relevant instruction" do
      @jtag.should_receive(:transmit_and_advance).with(anything, [0x09], 6, anything)
      @jtag.transmit_instruction([0x09], 6)
    end

    it "should put the device into the Exit1IR state after transmission." do

      #Ensure that our virtual target is placed into the Exit1 state _after_ transmission.
      LowLevel::JTAG::should_receive(:transmit_data).ordered
      @jtag.should_receive(:tap_state=).with(any_args)
      @jtag.should_receive(:tap_state=).with(Exit1IR)
      @jtag.transmit_instruction([0x09], 6)
    end

    it "should leave the device in the Exit1IR state" do
      @jtag.transmit_instruction([0x09], 6)
      @jtag.tap_state.should == Exit1IR
    end

    it "should correctly one-pad instructions to the chain length, when requested" do

      #Set an arbitrary chain length of 40
      @jtag.instance_variable_set(:@chain_length, 40)

      #And ensure that 33 ones are transmitted after the data itself.
      @jtag.should_receive(:transmit_and_advance).with(false, "\xAA", 7, anything).ordered.and_return("\x00")
      @jtag.should_receive(:transmit_and_advance).with(false, true, 33, anything).ordered.and_return("\x00\x00\x00\x00\x00")

      @jtag.transmit_instruction("\xAA", 7, true)

    end

    it "should correctly prefix the transmitted instruction with ones, when requested" do

      #And ensure that 20 ones are transmitted _before_ the instruction itself.
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), false, true, 20, false).ordered
      LowLevel::JTAG::should_receive(:transmit_data).with(kind_of(Numeric), false, "\xAA", kind_of(Numeric), false).ordered

      @jtag.transmit_instruction("\xAA", 7, false, 20)

    end

    it "should be able apply both a prefix and one-padding to a single instruction" do

      #Set an arbitrary chain length of 40
      @jtag.instance_variable_set(:@chain_length, 40)

      #Ensure that the 20 prefix ones are transmitted first, then the instruction, then the 13 padding ones.
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), false, true, 20, false).ordered
      LowLevel::JTAG::should_receive(:transmit_data).with(kind_of(Numeric), false, "\xAA", 7, false).ordered
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), anything, true, 12, false).ordered
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), anything, true, 1, false).ordered

      @jtag.transmit_instruction("\xAA", 7, true, 20)

    end

  end

  #
  # Trasmit TAP data
  #
  describe "#transmit_data" do

    it "should move the target into the ShiftDR state before transmission" do

      #Ensure that our virtual target is placed into the ShiftIR state _prior_ to transmission.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftDR, false, 4, false).ordered
      LowLevel::JTAG::should_receive(:transmit_data).ordered

      @jtag.transmit_data([0x09], 6)

    end

    it "should transmit the relevant data" do
      @jtag.should_receive(:transmit_and_advance).with(anything, [0x09], 6, anything)
      @jtag.transmit_instruction([0x09], 6)
    end

    it "should put the device into the Exit1DR state after transmission." do

      #Ensure that our virtual target is placed into the Exit1 state _after_ transmission.
      @jtag.should_receive(:tap_state=).with(any_args).ordered
      LowLevel::JTAG::should_receive(:transmit_data).ordered
      @jtag.should_receive(:tap_state=).with(Exit1DR).ordered

      @jtag.transmit_data([0x09], 6)

    end

    it "should leave the device in the Exit1DR state" do
      @jtag.transmit_data([0x09], 6)
      @jtag.tap_state.should == Exit1DR
    end

    it "should correctly zero-pad data to the chain length, when requested" do

      #Set an arbitrary device count.
      @jtag.instance_variable_set(:@devices_in_chain, 3)

      #And ensure that two zeroes are transmitted after the data itself, filling the bypass registers of
      @jtag.should_receive(:transmit_and_advance).with(false, "\xAA", 7, anything).ordered.and_return("\x00")
      @jtag.should_receive(:transmit_and_advance).with(false, false, 2, anything).ordered.and_return("\x00")

      @jtag.transmit_data("\xAA", 7, true)

    end

    it "should correctly prefix the transmitted data with zeroes, when requested" do

      #And ensure that 10 zeroes are transmitted _before_ the instruction itself.
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), false, false, 10, false).ordered
      LowLevel::JTAG::should_receive(:transmit_data).with(kind_of(Numeric), false, "\xAA", anything, false).ordered

      @jtag.transmit_data("\xAA", 7, false, 10)

    end

    it "should be able apply both a prefix and zero-padding to a single piece of data" do

      #Set an arbitrary chain length of 40
      @jtag.instance_variable_set(:@devices_in_chain, 10)

      #Ensure that the 20 prefix ones are transmitted first, then the instruction, then the 4 padding zeroes.
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), false, false, 5, false).ordered
      LowLevel::JTAG::should_receive(:transmit_data).with(kind_of(Numeric), false, "\xAA", 7, false).ordered
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), anything, false, 3, false).ordered
      LowLevel::JTAG::should_receive(:transmit_constants).with(kind_of(Numeric), anything, false, 1, false).ordered

      @jtag.transmit_data("\xAA", 7, true, 5) 

    end

  end

  #
  # Receive TAP data
  #
  describe "#receive_data" do

    it "should move the target into the ShiftDR state before receiving" do

      #Ensure that our virtual target is placed into the ShiftIR state _prior_ to transmission.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftDR, false, 4, false).ordered
      LowLevel::JTAG::should_receive(:receive).ordered

      @jtag.receive_data(6, true)

    end

    it "should receive the relevant data" do
      LowLevel::JTAG::should_receive(:receive).with(kind_of(Numeric), false, false, 6, false)
      @jtag.receive_data(6)
    end

    it "should put the device into the Exit1DR state after transmission." do

      #Ensure that our virtual target is placed into the Exit1 state _after_ transmission.
      @jtag.should_receive(:tap_state=).with(any_args).ordered
      LowLevel::JTAG::should_receive(:receive).ordered
      @jtag.should_receive(:tap_state=).with(Exit1DR).ordered

      @jtag.receive_data(6)

    end

    it "should leave the device in the Exit1DR state" do
      @jtag.receive_data(6)
      @jtag.tap_state.should == Exit1DR
    end

  end

  #
  # Transmit data, and advance the TAP FSM by a single state.
  #
  describe "#transmit_and_advance" do

    it "should send the data requested in two separate transmissions: one with all but the last bit, and one with the last bit" do
      LowLevel::JTAG::should_receive(:transmit).with(kind_of(Numeric), anything, "\xFF", 7, anything).ordered.and_return("\x00")
      LowLevel::JTAG::should_receive(:transmit).with(kind_of(Numeric), anything, true, 1, anything).ordered
      @jtag.send(:transmit_and_advance, true, "\xFF", 8, JTAG::TAPStates::Idle)  
    end

    it "should hold TMS at the provided constant for all but the last bit of the transmission" do
      LowLevel::JTAG::should_receive(:transmit).with(kind_of(Numeric), true, anything, kind_of(Numeric), anything).ordered.and_return("\x00")
      LowLevel::JTAG::should_receive(:transmit).with(any_args).ordered
      @jtag.send(:transmit_and_advance, true, "\xFF", 8, JTAG::TAPStates::Idle)  
    end

    it "should use the provided desired-state to determine the value of TMS during transmission of the final bit" do
      LowLevel::JTAG::should_receive(:transmit).with(any_args).ordered.and_return("\x00")
      LowLevel::JTAG::should_receive(:transmit).with(kind_of(Numeric), false, anything, 1, anything).ordered
      @jtag.send(:transmit_and_advance, true, "\xFF", 8, JTAG::TAPStates::Idle)  
    end

    it "should advance the TAP FSM according to the finite state machine" do
      LowLevel::JTAG::stub!(:transmit => "\x00")
      @jtag.send(:transmit_and_advance, true, "\xFF", 8, JTAG::TAPStates::Idle)  
      @jtag.tap_state.should == JTAG::TAPStates::Idle
    end

    it "should not vary TMS if the state to advance towards is nil" do
      LowLevel::JTAG::should_receive(:transmit).with(kind_of(Numeric), true, anything, 8, anything).and_return("\x00")
      @jtag.send(:transmit_and_advance, true, "\xFF", 8, nil)  
    end

    it "should not advance the TAP FSM if the state to advance towards is nil" do
      LowLevel::JTAG::stub!(:transmit => "\x00")
      @jtag.send(:transmit_and_advance, true, "\xFF", 8, nil)  
      @jtag.tap_state.should == JTAG::TAPStates::Reset
    end

    it "should return the combined values of the first and second transmissions" do
      LowLevel::JTAG::should_receive(:transmit).with(any_args).and_return("\x7F", "\x01")
      @jtag.send(:transmit_and_advance, true, "\xAA", 8, JTAG::TAPStates::Idle).should == "\xFF"
    end

  end

  describe "#add_bit_to_message" do
      
    it "should be able to merge a bit into a string of bytes" do
      @jtag.send(:add_bit_to_message, "\x7F", 7, true).should == "\xFF"
      @jtag.send(:add_bit_to_message, "\x7F\xFF", 15, true).should == "\xFF\xFF"
      @jtag.send(:add_bit_to_message, "\x7F\xFF", 15, false).should == "\x7F\xFF"
    end

  end

  describe "#bit_of_message" do 

    it "should return the provided bit from a string message" do
      @jtag.send(:bit_of_message, "\xAA\xAA", 0).should be_false
      @jtag.send(:bit_of_message, "\xAA\xAA", 1).should be_true
      @jtag.send(:bit_of_message, "\xAA\xAA", 14).should be_false
      @jtag.send(:bit_of_message, "\xAA\xAA", 15).should be_true
    end
    
    it "should return any provided boolean value directly, no matter the bit number" do
      @jtag.send(:bit_of_message, true,  0).should be_true
      @jtag.send(:bit_of_message, false, 0).should be_false
      @jtag.send(:bit_of_message, true,  8).should be_true
      @jtag.send(:bit_of_message, false, 8).should be_false
    end

  end


  #
  # Run the target device's test.
  #
  describe "#run_test" do

    it "should move the target into the Idle state prior to its main function" do

      path_to_idle = [0]

      #Ensure that our virtual target is placed into the ShiftIR state _prior_ to transmission.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), path_to_idle, false, 1, false).ordered
      LowLevel::JTAG::should_receive(:tick).ordered

      @jtag.run_test(100)

    end

    it "should cause TCK to tick the specified number of times with TDO/TMS low" do
      LowLevel::JTAG::should_receive(:tick).with(kind_of(Numeric), false, false, 100, false)
      @jtag.run_test(100)
    end

    it "should leave the device in the Idle state" do
      @jtag.run_test(100)
      @jtag.tap_state.should == Idle
    end

  end

  #
  # Enumerate all connected devices, by IDCode.
  #
  describe "#connected_devices" do

    it "should reset the device before proceeding" do
      @jtag.should_receive(:reset_target).ordered
      @jtag.should_receive(:receive_data).ordered.and_return("\x00\x00\x00\x00")

      @jtag.connected_devices
    end

    it "should return an empty array when no devices are detected" do
      @jtag.should_receive(:receive_data).and_return("\x00\x00\x00\x00")
      @jtag.connected_devices.should == []
    end

    it "should return an array of devices if IDcodes are recieved" do
      @jtag.should_receive(:receive_data).and_return("\x12\x34\x56\x78", "\xAB\xCD\xEF\xFF", "\x00\x00\x00\x00")
      @jtag.connected_devices.each { |d| d.class.kind_of?(Device)}
    end

    it "should return devices with the appropriate ID codes" do
      @jtag.should_receive(:receive_data).and_return("\x12\x34\x56\x78", "\xAB\xCD\xEF\xFF", "\x00\x00\x00\x00")
      idcodes = @jtag.connected_devices.collect { |d| d.idcode }
      idcodes.should == ["\xFF\xEF\xCD\xAB", "\x78\x56\x34\x12"]
    end

    it "should correctly determine the length of the instruction scan chain" do
      @jtag.should_receive(:receive_data).and_return("\x93\x50\x04\xD5", "\x93\xA0\xC1\x11", "\x00\x00\x00\x00")
      @jtag.connected_devices
      @jtag.instance_variable_get(:@chain_length).should == 8 + 6
    end

    it "should be able to identify the devices on a Basys2 board" do

      @jtag.should_receive(:receive_data).and_return("\x93\x50\x04\xD5", "\x93\xA0\xC1\x11", "\x00\x00\x00\x00")
      devices = @jtag.connected_devices

      #Check the ID Codes...
      idcodes = devices.collect { |d| d.idcode }
      idcodes.should == ["\x11\xC1\xA0\x93", "\xD5\x04\x50\x93"]

      #...  the types...
      types = devices.collect { |d| d.class }
      types.should == [JTAG::FPGA, JTAG::PlatformFlash]

      #... the positions in the chain...
      positions = devices.collect { |d| d.instance_variable_get(:@position_in_chain) }
      positions.should == [1, 0]

      #... and the chain widths.
      widths = devices.collect { |d| d.instance_variable_get(:@chain_offset) }
      widths.should == [8, 0]

    end


  end

end
