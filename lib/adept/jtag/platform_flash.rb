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

      InstructionWidth = 8
      supports_idcode "X5045093"

    end

  end
end
