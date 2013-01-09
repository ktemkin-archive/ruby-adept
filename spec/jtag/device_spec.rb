
require 'adept/jtag'

include Adept
include JTAG

#
# Tests for the JTAGDevice base module.
#
#
describe Device do

  before :all do

    #Create a simple test device "stub" class.
    class ADevice < Device

      def self.supports?(idcode)
        idcode == "\xAB\xCD\xEF\xFF"
      end

    end

  end

  describe ".included" do

    it "should keep track of all classes which extend JTAGDevice" do
      device_types = Device.instance_variable_get(:@device_types)
      device_types.should include(ADevice)
    end

  end

  describe "#device_from_idcode" do

    it "should be able to create devices with the appropriate type given their IDCode" do
      Device.device_from_idcode("\xAB\xCD\xEF\xFF", nil, 0).class.should == ADevice
    end

    it "should create a generic JTAGDevice when its IDCode isn't recognized" do
      Device.device_from_idcode("\x00\x00\x00\x00", nil, 0).class.should == Device
    end

  end


end
