
require 'adept'

module SpecHelpers

  #Stores the path to the testing firmware files.
  FirmwarePath = '../firmware'

  #
  # Loads a given piece of firmware onto a connected 
  #
  def preload_firmware(filename, board_class=Boards::Basys2)

    #Compute the relative path to the specified piece of firmware...
    path = File.expand_path("#{FirmwarePath}/#{filename}.bit", __FILE__)

    #... read the bitstream file at that path...
    bitfile = DataFormats::Bitstream.from_file(path)

    #... and program the file to the connected board.
    board_class.open { |board| board.configure_fpga(bitfile) }

  end

end
