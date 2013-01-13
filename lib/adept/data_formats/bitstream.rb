
require 'bindata'

require 'adept/data_formats/data_factories'

module Adept
  module DataFormats

    class BitStream < BinData::Record
      extend DataFactories

      endian :big
    
      #Bit-file header.
      uint16 :header_length
      string :header,         :read_length => :header_length
      skip   :length => 2

      #Design information.
      uint8 :a,              :check_value => 'a'.ord
      uint16 :info_length
      string :info,           :read_length => :info_length

      #Part information
      uint8 :b,              :check_value => 'b'.ord
      uint16 :part_length
      string :part,           :read_length => :part_length

      #Date of creation. 
      uint8 :c,              :check_value => 'c'.ord
      uint16 :date_length
      string :date,           :read_length => :date_length

      #Time of creation.
      uint8 :d,              :check_value => 'd'.ord
      uint16 :time_length
      string :time,           :read_length => :time_length

      #Raw binary configuration information
      uint8 :e,              :check_value => 'e'.ord
      uint32 :bitstream_length
      array  :bitstream,      :type => :uint8, :initial_length => :bitstream_length

      #
      # Parses the given string as a Xilinx BitStream file.
      #
      def self.from_string(string)
        self.read(string)
      end

    end

  end
end
