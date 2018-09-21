require "simplecov"
require "rspec"

SimpleCov.start do
  add_filter "/spec/"
end

require "ref_arch_setup"

RSpec.configure do |c|
end

RSpec.shared_context "case_info_lets" do
  let(:something) { "some value" }
end

def do_something_helpful(value)
  puts "Do something with #{value}"
end
