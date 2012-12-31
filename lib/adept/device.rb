
require 'adept/device_exception'

require 'adept/lowlevel'
require 'adept/lowlevel/device_manager'

module Adept

  #
  # Basic interface to a Digilent Adept device.
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
    # Factory method which returns a connection to the device with the given name,
    # or nil if no devices with that name could be found.
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



     


  end

end

