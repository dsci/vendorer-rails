$LOAD_PATH.unshift 'lib'
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '*.rb'))].each{|file| require file}
require 'vendorer'
require 'vendorer/version'

RSpec.configure do |config|
  config.include FileHelper
end