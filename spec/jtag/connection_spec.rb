#
# These tests assume _one_ single connected Basys2 board!
#

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

  before :all do
    @device = Device.by_name('Basys2')
  end

  after :all do
    @device.close
  end

  before :each do

    #Clear any expectations held by the low-level JTAG library.
    LowLevel::JTAG::rspec_reset

    #And establish a new JTAG Connection
    @jtag = JTAG::Connection.new(@device)
    @jtag.reset_target

  end

  after :each do
    @jtag.close
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
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftIR, false, 5)

      #Attempt to move the target into the ShiftIR state.
      @jtag.tap_state = ShiftIR

    end

    it "should adjust the internal state" do
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
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftIR, false, 5).ordered
      LowLevel::JTAG::should_receive(:transmit_data).ordered

      @jtag.transmit_instruction([0x09], 6, true)

    end

    it "should transmit the relevant data" do
      LowLevel::JTAG::should_receive(:transmit_data).with(kind_of(Numeric), false, [0x09], 6)
      @jtag.transmit_instruction([0x09], 6)
    end

    it "should put the device into the Exit1IR state after transmission." do

      #Ensure that our virtual target is placed into the Exit1 state _after_ transmission.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(any_args).ordered
      LowLevel::JTAG::should_receive(:transmit_data).ordered
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), [1], false, 1).ordered

      @jtag.transmit_instruction([0x09], 6)

    end

    it "should leave the device in the Exit1IR state" do
      @jtag.transmit_instruction([0x09], 6)
      @jtag.tap_state.should == Exit1IR
    end

  end

  #
  # Trasmit TAP data
  #
  describe "#transmit_data" do

    it "should move the target into the ShiftDR state before transmission" do


      #Ensure that our virtual target is placed into the ShiftIR state _prior_ to transmission. 
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftDR, false, 4).ordered
      LowLevel::JTAG::should_receive(:transmit_data).ordered

      @jtag.transmit_data([0x09], 6, true)

    end

    it "should transmit the relevant data" do
      LowLevel::JTAG::should_receive(:transmit_data).with(kind_of(Numeric), false, [0x09], 6)
      @jtag.transmit_data([0x09], 6)
    end

    it "should put the device into the Exit1DR state after transmission." do

      #Ensure that our virtual target is placed into the Exit1 state _after_ transmission.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(any_args).ordered
      LowLevel::JTAG::should_receive(:transmit_data).ordered
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), [1], false, 1).ordered

      @jtag.transmit_data([0x09], 6)

    end

    it "should leave the device in the Exit1DR state" do
      @jtag.transmit_data([0x09], 6)
      @jtag.tap_state.should == Exit1DR
    end

  end

  #
  # Receive TAP data
  #
  describe "#receive_data" do

    it "should move the target into the ShiftDR state before receiving" do

      #Ensure that our virtual target is placed into the ShiftIR state _prior_ to transmission. 
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), PathToShiftDR, false, 4).ordered
      LowLevel::JTAG::should_receive(:receive).ordered

      @jtag.receive_data(6, true)

    end

    it "should receive the relevant data" do
      LowLevel::JTAG::should_receive(:receive).with(kind_of(Numeric), false, false, 6)
      @jtag.receive_data(6)
    end

    it "should put the device into the Exit1DR state after transmission." do

      #Ensure that our virtual target is placed into the Exit1 state _after_ transmission.
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(any_args).ordered
      LowLevel::JTAG::should_receive(:receive).ordered
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), [1], false, 1).ordered

      @jtag.receive_data(6)

    end

    it "should leave the device in the Exit1DR state" do
      @jtag.receive_data(6)
      @jtag.tap_state.should == Exit1DR
    end

  end


  #
  # Run the target device's test.
  #
  describe "#run_test" do

    it "should move the target into the Idle state prior to its main function" do

      path_to_idle = [0]

      #Ensure that our virtual target is placed into the ShiftIR state _prior_ to transmission. 
      LowLevel::JTAG::should_receive(:transmit_mode_select).with(kind_of(Numeric), path_to_idle, false, 1).ordered
      LowLevel::JTAG::should_receive(:tick).ordered

      @jtag.run_test(100)

    end

    it "should cause TCK to tick the specified number of times with TDO/TMS low" do
      LowLevel::JTAG::should_receive(:tick).with(kind_of(Numeric), false, false, 100)
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

    it "should return an array of idcodes, when they are received" do
      @jtag.should_receive(:receive_data).and_return("\x12\x34\x56\x78", "\xAB\xCD\xEF\xFF", "\x00\x00\x00\x00")
      @jtag.connected_devices.should == ["\xFF\xEF\xCD\xAB", "\x78\x56\x34\x12"]
    end

    it "should be able to identify the devices on a Basys2 board" do
      @jtag.connected_devices.should == ["\x11\xC1\xA0\x93", "\xD5\x04\x50\x93"]
    end

  end

end
