#
# FPGA JTAG Target
#

require 'adept/jtag'

module Adept
  module JTAG

    #
    # Base module for JTAG devices.
    #
    class FPGA < Device

      IDCodeSpartan3E = "5045093"
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


    end

  end
end
