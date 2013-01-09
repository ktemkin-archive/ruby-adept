#
# FPGA JTAG Target
#

require 'adept/jtag'
require 'adept/jtag/xilinx_device'

module Adept
  module JTAG

    #
    # Base module for JTAG devices.
    #
    class FPGA < Device
      extend XilinxDevice

      IDCodeSpartan3E = "1c1a093"
      SupportedIDCodes = [IDCodeSpartan3E]

      #
      # Indicates whether the given IDCode corresponds to a supported FPGA device.
      #
      def self.supports?(idcode)

        #Get the IDCode for the device without the chip's mask ID.
        idcode = idcode.unpack("H*").first[1..-1]

        #A device is supported if it has a known IDCode.
        SupportedIDCodes.include?(idcode)

      end

      #
      # Return the instruction width of a Xilinx FPGA.
      # 
      def instruction_width
        return 6
      end


    end

  end
end
