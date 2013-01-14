
require 'date'
require 'bindata'

require 'adept/data_formats/data_factories'

module Adept
  module DataFormats

    #
    # Class for the Xilinx bitstream file format.
    #
    # Format used was described at 
    # <http://www.fpga-faq.com/FAQ_Pages/0026_Tell_me_about_bit_files.htm>
    #
    class Bitstream < BinData::Record
      extend DataFactories

      #Data is stored in the bitstream in big endian format.
      endian :big
 
      #Bit-file header.
      uint16 :header_length
      string :header,           :read_length => :header_length
      skip   :length => 2

      #Design information.
      uint8  :a,                :check_value => 'a'.ord
      uint16 :info_length
      string :info,             :read_length => :info_length, :trim_padding => true

      #Part information
      uint8  :b,                :check_value => 'b'.ord
      uint16 :part_length
      string :part,             :read_length => :part_length, :trim_padding => true

      #Date of creation.
      uint8  :c,                :check_value => 'c'.ord
      uint16 :date_length
      string :raw_date,         :read_length => :date_length, :trim_padding => true

      #Time of creation.
      uint8  :d,                :check_value => 'd'.ord
      uint16 :time_length
      string :raw_time,         :read_length => :time_length, :trim_padding => true

      #Raw binary configuration information
      uint8  :e,                :check_value => 'e'.ord
      uint32 :bitstream_length
      array  :raw_bitstream,        :type => :uint8, :initial_length => :bitstream_length

      UsercodeFormat= /UserID=0x([0-9A-Fa-f]+)/
      
      #
      # Parses the given string as a Xilinx BitStream file.
      #
      def self.from_string(string)
        read(string)
      end

      #
      # Returns the routed logic ("ncd") filename from which this bitstream was created.
      #
      def filename
        info.split(';').first
      end

      #
      # Returns the usercode for the given design.
      #
      def usercode
        UsercodeFormat.match(info)[1]
      end

      #
      # Returns the time at which the bitfile was created.
      #
      def time_created
        DateTime.parse("#{raw_date} #{raw_time}")
      end

      #
      # Returns the length of the bitsream, in bits.
      #
      def bit_length
        bitstream_length * 8
      end

      #
      # Returns the bitstream as an arran array.
      #
      def to_a
        raw_bitstream.to_a.map { |b| self.class.reverse_byte(b) }
      end

      #
      # Returns the bitstream as a bit string.
      #
      def to_s
        to_a.pack("C*")
      end

      private 

      #
      # Reverses the bit order of a given byte, using a fast algorithm from the
      # following page: http://graphics.stanford.edu/~seander/bithacks.html
      #
      def self.reverse_byte(byte)
         (((byte * 0x0802 & 0x22110) | (byte * 0x8020 & 0x88440)) * 0x10101 >> 16) % 0x100;
      end

    end

  end
end
