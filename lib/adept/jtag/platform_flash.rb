#
# FPGA Configuration Platform Flash
#

require 'adept/jtag'
require 'adept/jtag/xilinx_device'

module Adept
  module JTAG

    #
    # Base module for JTAG devices.
    #
    class PlatformFlash < Device
      extend XilinxDevice

      IDCodePlatformFlash = "5045093"
      SupportedIDCodes = [IDCodePlatformFlash]

      #
      # Return the instruction width for a Xilinx Platform Flash device.
      # 
      def instruction_width
        return 8
      end


    end

  end
end
