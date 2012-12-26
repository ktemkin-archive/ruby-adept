require 'ffi'
require 'adept/lowlevel/device'

module Adept
  module LowLevel

    #
    # DeviceManager (DMGR)
    # Wrapper for the low-level Adept device management functionality.
    #
    module DeviceManager
      extend FFI::Library

      #Wrap the device manager library, libDMGR
      ffi_lib 'libdmgr.so'

      #
      # Meta-information functions.
      #

      #Get the device manager's runtime verison.
      attach_function :DmgrGetVersion, [:pointer], :void

      #
      # Error handling functions.
      #

      #Get the most recent error code.
      attach_function :DmgrGetLastError, [], :int
      attach_function :DmgrSzFromErc, [:int, :pointer, :pointer], :void

      #
      #Enumeration functions.
      #

      #Get the list of all detected Adept devices; should be followed by the accompanying FreeDvcEnum call.
      attach_function :DmgrEnumDevices, [:pointer], :void

      #Free the internal list of connected devices.
      attach_function :DmgrFreeDvcEnum, [], :void




    end

  end
end
