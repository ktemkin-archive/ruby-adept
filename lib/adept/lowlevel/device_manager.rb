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
      # Enumeration functions.
      #

      #Get the list of all detected Adept devices; should be followed by the accompanying FreeDvcEnum call.
      attach_function :DmgrEnumDevices, [:pointer], :void

      #Free the internal list of connected devices.
      attach_function :DmgrFreeDvcEnum, [], :void


      #
      # Populate the internal list of connected devices.
      # Returns the total amount of devices enumerated.
      #
      def self.populate_device_list

        #Create a pointer to a new C integer.
        count_pointer = FFI::MemoryPointer.new(:int)
        
        #Enumerate all of the connected devices, and retrieve the amount of enumerated devices.
        DmgrEnumDevices(count_pointer)

        #Dereference the count pointer, extracting the number of devices present.
        count_pointer.get_int(0)

      end

      #
      # Free the internal list of connected devices.
      #
      def self.free_device_list
        DmgrFreeDvcEnum()
      end


      #
      # Device Information-Query Functions
      #
      
      #Get all enumeration information regarding the current device.
      attach_function :DmgrGetDvc, [:int, :pointer], :void

      #
      # Returns a single record from the internal device enumeration list.
      # This record contains low-level information about how to connect to the device.
      #
      def self.get_device_info(device_number)

        #Create a new, empty low-level device structure.
        device = Device.new

        #Get the device's information from the internal enumeration table.
        DmgrGetDvc(device_number, device.pointer)

        #And return the newly-fetched device object as a ruby hash.
        device.to_h

      end

      #
      # Device Open/Close Functions
      #
      
      #Open the device at the specified path.
      attach_function :DmgrOpen, [:pointer, :string], :void

      #Close the device with the specified handle.
      attach_function :DmgrClose, [:ulong], :void

      #
      # Opens the device at the given path, and returns an interface handle.
      #
      def self.open_device(path)

        #Create a pointer to a new C long.
        handle_pointer = FFI::MemoryPointer.new(:ulong)

        #Open the device at the given path, retrieving the newly-created device handle.
        DmgrOpen(handle_pointer, path)

        #Dereference the handle pointer, retrieving the handle itself.
        handle = handle_pointer.get_ulong(0)

        #If we recieved a handle of zero (C's NULL), convert that to nil;
        #otherwise, return the handle directly.
        handle.zero?() ? nil : handle

      end

      #
      # Closes the device which is referenced by the given interface handle.
      #
      def self.close_device(handle)
        DmgrClose(handle)
      end


    end

  end
end
