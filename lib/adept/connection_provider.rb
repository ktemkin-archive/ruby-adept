
module Adept

  #
  # Base for Adept connections.
  # 
  module ConnectionProvider

    # An internal list of connection types which are provided by this library.
    # Each time a new Conneciton type is loaded, it is added to this array.
    @supported_connections = []

    #
    # Triggered each time a target class extends this basic connection.
    # Stores a list of all classes that extend ConnectionBase.
    #
    def self.extended(connection)
      @supported_connections << connection
    end

    #
    # Returns the list of all supported connection providers.
    #
    def self.providers
      @supported_connections
    end

  end

end
