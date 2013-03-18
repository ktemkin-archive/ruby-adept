require 'adept'
require 'yaml'
require 'tempfile'

module Adept


  #
  # Class which represents a data-2-mem configurable IP core.
  # 
  class Core

    attr_reader :name
    attr_reader :targets
   
    #
    # Returns a list of all available cores, optionally filtered by a device ID string.
    #
    def self.available_cores(device=nil)

      #Determine the path at which the ruby-adept gem is stored.
      gem_path = File.expand_path('../..', File.dirname(__FILE__))

      #Get a list of all available core definition files.
      core_definitions = Dir["#{gem_path}/cores/**/core.yaml"]

      #Convert each definition to a YAML core.
      definitions = core_definitions.map { |file| from_definition_file(file) }

      #If we were passed a device shortname to filter by, ensure we
      #only return cores that support that target.
      unless device.nil?
        definitions = definitions.select { |core| core.targets.include?(device) }
      end

      definitions


    end

    #
    # Creates a new Core object from a YAML definition file.
    #
    # file: The full path to a YAML core definition file.
    #
    def self.from_definition_file(file)

      #Get the path of the directory that holds the core's files.
      base_path = File.dirname(file)

      #Parse the YAML definition file.
      raw_definition = YAML.load_file(file)

      #Return a new core object. 
      new(raw_definition["name"], base_path, raw_definition["targets"])

    end

    #
    # Initializes a new instance of a Core object.
    #
    def initialize(name, base_path, targets)
      @name = name
      @base_path = base_path
      @targets = targets
    end

    #
    #  Configures the given 
    #
    def configure(elf_file, target=@targets.keys.first)

      #Ensure the target is a string.
      target = target.to_s
    
      #Get the path to the bitfile and memory map which will be used to generate the new bitfile.
      memory_map = "#@base_path/#{@targets[target]['memory_map']}"
      bit_file   = "#@base_path/#{@targets[target]['bit_file']}"

      p target, bit_file

      #Generate the new raw bitfile...
      hex = with_temporary_files                      { |dest, _|      system("avr-objcopy -O ihex -R .eeprom -R .fuse -R .lock #{elf_file} #{dest}") } 
      mem = with_temporary_files(hex, '.mem', '.hex') { |dest, source| system("srec_cat #{source} -Intel -Byte_Swap 2 -Data_Only -Line_Length 100000000 -o #{dest} -vmem 8") }
      bit = with_temporary_files(mem, '.bit', '.mem') { |dest, source| system("data2mem -bm #{memory_map} -bt #{bit_file} -bd #{source} -o b #{dest}") }

      #... wrap it in a Bitstream object, and return it.
      Adept::DataFormats::Bitstream.from_string(bit)

    end

    #
    # Print a debugging represntation of the core.
    #
    def inspect
      "<IP Core 0x#{object_id.to_s(16)}: #@name>"
    end

    private


    #
    # Executes a given block with an "anonymous" temporary file.
    # The temporary file is deleted at the end of the block, and its contents
    # are returned.
    # 
    def with_temporary_files(file_contents='', dest_extension = '', source_extension = '', message=nil)

      #File mode for all of the created temporary files.
      #Create the files, and allow read/write, but do not lock for exclusive access.
      file_mode = File::CREAT | File::RDWR

      #Create a new file which contains the provided file content.
      #Used to pass arbitrary data into an external tool.
      Tempfile.open(['core_prev', source_extension], :mode => file_mode) do |source_file|

        #Fill the source file with the provided file contents...
        source_file.write(file_contents)
        source_file.flush

        #Create a new file which will store the resultant file content.
        Tempfile.open(['core_next', dest_extension], :mode => file_mode) do |destination_file|

          #Yield the file's paths the provided block.
          raise CommandFailedError, message unless yield [destination_file.path, source_file.path]

          #And return the content of the destination file.
          return File::read(destination_file)

        end

      end
    end

  end
end
