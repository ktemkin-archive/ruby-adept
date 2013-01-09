
module Adept
  module JTAG

    #
    # Standard functions for Xilinx devices.
    #
    module XilinxDevice

      #
      # Indicates whether the given IDCode corresponds to a supported device.
      #
      def supports?(idcode)

        #Get the IDCode for the device without the chip's mask ID.
        idcode = idcode.unpack("H*").first[1..-1]

        #A device is supported if it has a known IDCode.
        self::SupportedIDCodes.include?(idcode)

      end


    end

  end
end
