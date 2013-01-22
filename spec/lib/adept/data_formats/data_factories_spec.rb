
require 'adept'
require 'adept/data_formats'

#
#Use FakeFS, so none of the calls below actually touch the filesystem.
#
require 'rspec/mocks'
require 'rspec/expectations'
require 'fakefs/spec_helpers'

include Adept

#
# Tests for the DataFactories module.
#
describe Adept::DataFormats::DataFactories do
  subject { Object.new.extend(Adept::DataFormats::DataFactories) }

  describe "#from_file" do
    include FakeFS::SpecHelpers

    before :each do
      File::open('test', 'w') { |x| x.write('ABCDE') }
    end

    context "when given a filename" do
      it "should call from_string with the file's contents" do
        subject.should_receive(:from_string).with('ABCDE')
        subject.from_file('test')
      end
    end

    context "when given a file object" do
      it "should call from_string with the file's contents" do
        subject.should_receive(:from_string).with('ABCDE')
        File::open('test', 'r') { |file| subject.from_file(file) }
      end
    end

  end
end
