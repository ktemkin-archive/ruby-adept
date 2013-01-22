#
# These tests assume _one_ single connected Basys2-250K board!
#

require 'adept'
require 'adept/low_level'

require 'spec_helpers'
include SpecHelpers

#Pull the relevant modules into the main namespace, for convenience.
include Adept

describe LowLevel::EnhancedParallel do

  subject { LowLevel::EnhancedParallel }

  describe "on-line functionality", :online => true, :long => true do

    #Program the Basys board with the EPP loopback program, for testing.
    before :all do
      preload_firmware 'epp_loopback'
    end

    before :each do
      @device = Boards::Basys2.new
    end

    after :each do
      @device.close
    end

    #Get an easy reference to the device's handle.
    let(:handle) { @device.handle }


    it "should detect that a Basys2 board supports EPP" do
      subject.supported?(handle).should be_true
    end

    it "should detect exactly one EPP port on a Basys2 board" do
      subject.port_count(handle).should == 1
    end

    it "should be able to open an EPP connectoin " do
      subject.EnableEx(handle, 0)
    end

    it "should be able to _close_ an EPP connection" do
      subject.EnableEx(handle, 0)
      subject.Disable(handle)
    end

    describe "post-connection tests" do

      before :each do
        subject.EnableEx(handle, 0)
      end

      after :all do
        subject.Disable(handle)
      end

      it "should be able to get/set the value of the given EPP register" do
        subject.set_register_value(handle, 0, 123)
        subject.get_register_value(handle, 0).should == 123
      end

    end

  end
end
