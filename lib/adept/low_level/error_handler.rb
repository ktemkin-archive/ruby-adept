require 'ffi'
require 'adept/low_level/device_error'

module Adept
  module LowLevel

    #Maximum length of an error messsage's shortname, with null terminator.
    ErrorNameMaxLength = 16

    #Maximum length of an error message's description, with null terminator.
    ErrorMessageMaxLength = 128

    #
    # Basic low-level error handler.
    #
    # This class implements the basic error reporting functionality from the Digilent Device Manager API. 
    # It is intentionally separate from the low-level DeviceManager wrapper, so error checking works even if
    # the AdeptLibrary class fails during development.
    #
    module ErrorHandler
      extend FFI::Library

        ffi_lib 'libdmgr'

        #
        # Error handling functions.
        #

        #Get the most recent error code.
        attach_function :DmgrGetLastError, [], :int
        attach_function :DmgrSzFromErc, [:int, :pointer, :pointer], :void

        #
        # Returns a DeviceError which encapsulates the most recent error,
        # in a format which can be easily raised.
        #
        def self.last_error

          #get the error code most recently seen by the device manager API.
          code = DmgrGetLastError()

          #if no error has occurred, return nil.
          return nil if code.zero?
      
          #Create space for the error name and message...
          error_name = FFI::MemoryPointer.new(ErrorNameMaxLength)
          error_message = FFI::MemoryPointer.new(ErrorMessageMaxLength)

          #... and populate those spaces with the relevant error information.
          DmgrSzFromErc(code, error_name, error_message)

          #Convert the error information into a DeviceError.
          DeviceError.new(error_message.read_string, error_name.read_string, code)

        end

    end
  end
end

