
require 'adept'

#
# Specification for the Adept Device interface.
# These tests assume _only_ one connected Basys2 board!
#
describe Adept::Core do

  let(:avr8) { 'ATMega103-compatible AVR' }

  #
  # Matcher which returns true if the given list contains the AVR-8.
  # 
  RSpec::Matchers.define :include_a_core_named do |expected|
    match do |given|
      given.find { |core| core.name == expected }
    end

    failure_message_for_should { |given| "expected #{actual.inspect} to contain a core named '#{expected}'" }
    failure_message_for_should_not { |given| "expected #{actual.inspect} to not contain a core named '#{expected}'" }
  end


  describe "class methods" do

    describe "#available_cores" do
      subject { Adept::Core }

      it "should return an array of known cores" do
        
        #Get a list of all available cores...
        cores = subject.available_cores

        #... and validate their types.
        cores.should be_an Array
        cores.all? { |x| x.should be_a Adept::Core}

      end

      context "when provided with a device name" do
        it "should return only the cores that correspond to that device name" do
          subject.available_cores('invalidDevice').should_not include_a_core_named avr8
        end
      end

      context "when a device name is not provided" do
        it "should return all known cores as core objects" do
          subject.available_cores('3s250ecp132').should include_a_core_named avr8
        end
      end

    end

  end

end

