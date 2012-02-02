require 'active_record'
require 'fast_change_table/connection_adapters'
require 'fast_change_table/fast_change_table'
require 'fast_change_table/version'

module FastChangeTable
  def self.included(base)
    base.extend ClassMethods
  end
end

::ActiveRecord::Migration.send :include, FastChangeTable