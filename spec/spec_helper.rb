require 'rubygems'
require 'bundler/setup'

require 'fast_change_table'

RSpec.configure do |config|
  # some (optional) config here
end

ActiveRecord::Base.establish_connection(
:adapter => "mysql2",
:database => "fast_change_table_test"
)


