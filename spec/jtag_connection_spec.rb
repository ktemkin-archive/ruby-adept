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
describe JTAGConnection do

  PathToShiftDR = ["0100".to_i(2)]
  PathToShiftIR = ["01100".to_i(2)]

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
    @jtag = JTAGConnection.new(@device)
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

      it "should move the target into the Exit1IR state before transmission" do

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

      it "should move the target into the Exit1DR state before transmission" do

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
  
  end
end
