
require 'adept/device_exception'

require 'adept/lowlevel'
require 'adept/lowlevel/device_manager'

module Adept

  #
  # Represents a Digilent Adept device.
  # 
  class Device

    #Get an easy reference to the adept Device Manager API.
    DeviceManager = LowLevel::DeviceManager

    #Allow Device connections to be created with an open function,
    #like Ruby I/O objects.
    alias :new :open

    #Allow access to the device's handle, for now.
    attr_accessor :handle

    #
    #Creates a new connection to a Digilent adept device.
    #
    def initialize(path)

      #Open the device, and store its handle.
      @handle = DeviceManager::open_device(path) 

      #If we didn't get a valid handle, raise the relevant exception.
      if @handle.nil?
        raise self.class.last_error
      end

    end

    #
    # Closes the given device.
    #
    def close
      ensure_handle_is_valid
      DeviceManager::close_device(@handle)
    end

    #
    # TODO: throw an exception of our handle is nil
    #
    def ensure_handle_is_valid

    end

    #
    # Returns the first device instance with the given name;
    # or nil if no devices with that name are connected.
    #
    def self.by_name(name)

      #Find the first device with the given name.
      target_device = connected_devices.find { |device| device[:name] == name }

      #If we didn't find a device, return nil.
      return nil if target_device.nil?

      #Return a new connection to the target device.
      self.new(target_device[:connection])

    end

    #
    # Returns an array of information regarding connected devices.
    # Each array member is a hash, with three members:
    #  -:name, the device's shortname
    #  -:connection, the device's connection
    #  -:transport, a code indicating the method by which we're connecting to the device
    #
    def self.connected_devices
     
      #Populate the internal device list, retrieving the amount of connected devices.
      count = DeviceManager::populate_device_list

      #Get the device information for each of the given devices.
      devices = (0...count).map { |index| DeviceManager::get_device_info(index) }

      #Free the internal device list.
      DeviceManager::free_device_list

      #and return the list of connected devices
      devices

    end

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

