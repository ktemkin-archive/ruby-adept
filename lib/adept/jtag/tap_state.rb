
module Adept
  module JTAG
    module TAPStates

      #
      # Base for all Test Access Port states.
      #
      module TAPState
      
        #
        # Returns the successor to the current state, given an input value.
        #
        def next_state(value)

          #Get the name of the module which describes the successor state...
          state = self::NextState[value]

          #... and get a reference to the module itself.
          TAPStates.const_get(state)

        end

        #
        # Determines the next value which should be present on the mode-set line
        # to get to the given state.
        #
        def next_hop_towards(state)

          #Get a refrence to the state module indicated by the TowardsZeroIfStateIs metaconstant.
          towards_zero = TAPStates.const_get(self::NextState[0])
          towards_one  = TAPStates.const_get(self::NextState[1])

          #Determine if a next-hop of one would cause us to get stuck in a loop.
          towards_one_would_cause_loop = (towards_one == self || self::NextState[1] == :Reset)

          #If the next state would be achievable by providing a hop of zero, 
          #or a hop of one would cause a loop, then the next hop should be zero.
          #
          #Otherwise, the next hop should be '1'.
          ((state == towards_zero) || towards_one_would_cause_loop) ? [0, towards_zero] : [1, towards_one]
        end

      end

      #
      # Dynamically create a new TAPState module.
      #
      def self.tap_state(name, next_state)

        #Create a new Module for the new TAP state...
        mod = Module.new

        #... and assign it the given name.
        self.const_set(name, mod)

        #Add the TAPState methods to the new module...
        mod.extend(TAPState)

        #And set the module's NextState constant, as given.
        mod.const_set(:NextState, next_state)

      end
    
    end
  end
end
