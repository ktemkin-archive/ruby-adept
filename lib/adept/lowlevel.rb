require 'ffi'


module Adept
  module LowLevel

    #
    # Constants; taken directly from the Digilent header file 'dpcdecl.h'.
    #
    
    #Maximum possible length of a library version string.
    VersionMaxLength = 256

    #Maximum length of an error messsage's shortname and description.
    ErrorNameMaxLength = 16
    ErrorMessageMaxLength = 128

  end
end
