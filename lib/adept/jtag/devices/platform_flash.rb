#
# FPGA Configuration Platform Flash
#

require 'adept/jtag'

module Adept
  module JTAG
    module Devices

      #
      # Base module for JTAG devices.
      #
      class PlatformFlash < Device

        InstructionWidth = 8
        supports_idcode "X5045093"

      end

    end
  end
end
