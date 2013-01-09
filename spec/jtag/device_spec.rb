
require 'adept/jtag'

include Adept

#
# Tests for the JTAGDevice base module.
#
#
describe Device do

  before :all do

    #Create two simple test devices "stub" class.
    class DeviceA < JTAG::Device
      InstructionWidth = 6
      Instructions = { :instruct => 0b101010 }
      supports_idcode "abcdefff"
    end

    class DeviceB < JTAG::Device
      InstructionWidth = 8
      Instructions = { :instruct => 0b10101010 }
      supports_idcode "01020304"
    end

  end

  describe ".included" do

    it "should keep track of all classes which extend JTAGDevice" do
      device_types = Device.instance_variable_get(:@device_types)
      device_types.should include(DeviceA, DeviceB)
    end

  end

  describe "#instruction_width" do

    it "should return the correct instruction width a given device" do
      DeviceA.new(nil, nil, 0, 0).instruction_width.should == 6
      DeviceB.new(nil, nil, 0, 0).instruction_width.should == 8
    end

  end

  describe "#device_from_idcode" do

    it "should be able to create devices with the appropriate type given their IDCode" do
      JTAG::Device.from_idcode("\xAB\xCD\xEF\xFF", nil, 0, 0).class.should == DeviceA
      JTAG::Device.from_idcode("\x01\x02\x03\x04", nil, 0, 0).class.should == DeviceB
    end

    it "should create a generic JTAGDevice when its IDCode isn't recognized" do
      JTAG::Device.from_idcode("\x00\x00\x00\x00", nil, 0, 0).class.should == Device
    end

  end

  describe "device communication functions" do

    let(:connection)  { mock(JTAG::Connection) }
    let(:device)      { DeviceB.new("\xAB\xCD\xEF\xFF", connection, 1, 6) }


    describe "#instruction=" do

      it "should set the target device's instruction, and place the rest of the chain into bypass"  do
        connection.should_receive(:transmit_instruction).with("\xAA", device.instruction_width, true, 6)
        device.instruction = "\xAA"
      end

      it "should accept instructions in numeric format" do
        connection.should_receive(:transmit_instruction).with("\xAA", device.instruction_width, true, 6)
        device.instruction = 0b10101010
      end

      it "should accept symbolic names for known instructions" do
        connection.should_receive(:transmit_instruction).with("\xAA", device.instruction_width, true, 6)
        device.instruction = :instruct
      end


    end

    describe "#transmit_data" do

      it "should send the target device's data, prefixed with enough zeroes to pass through the preceeding devices' bypass registers" do
        connection.should_receive(:transmit_data).with("\xAA", 7, true, kind_of(Numeric))
        device.transmit_data("\xAA", 7)
      end

    end
  end
end
