
module Adept
  module DataFormats

    #
    # Mixin which supports creating instances of data-storage containers
    # from files. Classes which extend this mix-in should have a "from_string" 
    # class method.
    #
    module DataFactories

        #
        # Creates a new instance of the target class from a file or filename.
        #
        def from_file(file)

          #If we have a file object, read it into memory.
          if file.respond_to?(:read)
            file = file.read
          #Otherwise, assume we have a filename.
          else
            file = File::read(file)
          end

          #Create a new instance of the extending class from the given file.
          from_string(file)

        end

    end

  end
end
