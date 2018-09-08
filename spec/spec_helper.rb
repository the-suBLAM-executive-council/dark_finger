$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dark_finger'
require 'rubocop'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include(RuboCop::RSpec::ExpectOffense)
end
