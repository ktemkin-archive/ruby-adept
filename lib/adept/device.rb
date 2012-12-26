
require 'adept/device_exception'

require 'adept/lowlevel'
require 'adept/lowlevel/device_manager'

module Adept

  #
  # Represents a Digilent Adept device.
  # 
  class Device

    DeviceManager = LowLevel::DeviceManager

 
    #
    # Returns a DeviceError which encapsulates the most recent error,
    # in a format which can be easily raised.
    #
    def self.last_error

      #get the error code most recently seen by the device manager API.
      code = DeviceManager::DmgrGetLastError()

      #if no error has occurred, return nil.
      return nil if code.zero?
  
      #Create space for the error name and message...
      error_name = LowLevel::create_error_name_buffer
      error_message = LowLevel::create_error_message_buffer

      #... and populate those spaces with the relevant error information.
      DeviceManager::DmgrSzFromErc(code, error_name, error_message)

      #Convert the error information into a DeviceError.
      DeviceError.new(error_message.read_string, error_name.read_string, code)

    end

    #
    # Returns the version of the Adept Device Manager runtime, as a string.
    #
    def self.runtime_version
      
      #create a new buffer which will hold the runtime's version
      version_buffer = LowLevel::create_version_buffer

      #get the system's version
      DeviceManager::DmgrGetVersion(version_buffer)

      #and return the retrieved version
      version_buffer.read_string

    end

     


  end

end

