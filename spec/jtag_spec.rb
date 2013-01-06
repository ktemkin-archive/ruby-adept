#
# These tests assume _one_ single connected Basys2 board!
#

require 'adept'
require 'adept/jtag/tap_states'

#Pull the relevant modules into the main namespace, for convenience.
include Adept
include JTAG::TAPStates

#
#
describe JTAGConnection do

  before :all do
    @device = Device.by_name('Basys2')
  end

  after :all do
    @device.close
  end

  before :each do
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

  end


end
