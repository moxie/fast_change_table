require "activerecord"
require "fast_change_table/version"

module FastChangeTable
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def fast_change_table(table_name, &block)
      old_table_name = "old_#{table_name}"
      rename_table(table_name, old_table_name)
      begin
         execute "CREATE TABLE #{table_name} LIKE #{old_table_name}" 
         change_table(table_name, &block)
         #prepare the columns names for the insert statements
         old = connection.columns(old_table_name).collect(&:name)
         current = connection.columns(table_name).collect(&:name)
         common = (current & old).sort
         columns_to_s = common.collect {|c| "`#{c}`"}.join(',')
         execute "INSERT INTO #{table_name}(#{columns_to_s}) SELECT #{columns_to_s} FROM #{old_table_name}" 
         drop_table(old_table_name)
      rescue
         drop_table(table_name) if table_exists?(table_name)
         rename_table(old_table_name, table_name)
      end
    end
  end
end

::ActiveRecord::Migration.send :include, FastChangeTable