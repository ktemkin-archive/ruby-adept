
require 'adept'

module Adept
  module Boards

    #
    # Basys2 System Board
    # 
    class Basys2 < Adept::Device
   
      DEVICE_NAME = 'Basys2'

      #
      # Creates a new Basys2 board instance given the device's path.
      # If no path is provided, the first connected Basys 2 board is used.
      #
      def initialize(path=nil)

        #If no path was provided, use the path to the first device found.
        path ||= Device.path_to(DEVICE_NAME) 

        #Delegate the connection tasks to the base class.
        super(path)

      end

      #
      # Creates a new Basys2 board instance, using the same syntax as new,
      # but accepts an optional block. If a block is given, the device will
      # be automatically closed after the block is complete.
      #
      # Yields and returns the newly-created device.
      #
      def self.open(path=nil)

        #Create a new Basys2 device.
        device = new(path)

        #If we were provided with a block, yield the device to it, 
        #and then close the device afterwards
        if block_given?
          begin
            yield device
          ensure
            device.close
          end
        end

        #Return the newly created device.
        device

      end

      #
      # Configures the Basys2 board's on-board FPGA.
      # Requires use of the board's JTAG port, and thus cannot be used when its JTAG
      # port is open. (The JTAG device API provides an alternative method for device
      # configuration.)
      #
      # bitstream: The bitstream to be programmed, as a Bitstream object or byte-string
      #   (without headers).
      #
      def configure_fpga(bitstream)

        begin

          #Create a new JTAG connection to the board's FPGA.
          jtag = JTAG::Connection.new(self)
          fpga = jtag.connected_devices.first

          #Configure the FPGA.
          fpga.configure(bitstream)

        ensure
          jtag.close
        end

      end

    end

  end
end
