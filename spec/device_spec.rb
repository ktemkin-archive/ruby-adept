#
# These tests assume _one_ single connected Basys2 board!
#

require 'adept'

#Pull the relevant modules into the main namespace, for convenience.
include Adept

#
# Specification for the Adept Device interface.
# These tests assume _only_ one connected Basys2 board!
#
describe Device do

  describe ".connected_devices" do

    it "should be able to enumerate the connected devices" do

      devices = Device.connected_devices

      #We should detect only a single device; which should be our Basys2 board.
      devices.count.should == 1
      devices.first[:name].should == 'Basys2'
      devices.first[:path].should include('usb')

    end

  end

  describe ".open" do

    it "should be able to connect to a board by path" do

      #Get the path of a connected device.
      path = Device.connected_devices.first[:path]

      #And open the device.
      device = Device.open(path)

      #The connected handle should be non-zero.
      device.handle.should_not == 0

      #Close the device afterwards
      device.close

    end
  end

  describe ".by_name" do

    it "should be able to connect to a device by name" do

      #Try to connect to a Basys board...
      device = Device.by_name('Basys2')

      #Ensure we got a valid handle.
      device.handle.should_not == 0

      #Close the device afterwards
      device.close

    end

  end

  #TODO: ensure that the device-list is free'd afterwards

end
