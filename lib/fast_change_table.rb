require "activerecord"
require "fast_change_table/version"

module FastChangeTable
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def fast_change_table(table_name, options = {}, &block)
      options.symbolize_keys!
      old_table_name = "old_#{table_name}"
      rename_table(table_name, old_table_name)
      begin
         create_table_like(old_table_name, table_name, &block)
         index_list = options[:disable_keys] ? disable_indexes(table_name) : []
         #prepare the columns names for the insert statements
         old = connection.columns(old_table_name).collect(&:name)
         current = connection.columns(table_name).collect(&:name)
         common = (current & old).sort
         columns_to_s = common.collect {|c| "`#{c}`"}.join(',')
         execute "INSERT INTO #{table_name}(#{columns_to_s}) SELECT #{columns_to_s} FROM #{old_table_name}"
         enable_indexes(table_name, index_list)
         drop_table(old_table_name)
      rescue Exception => e
        puts "#{e}\n#{e.backtrace}"
         drop_table(table_name) if table_exists?(table_name)
         rename_table(old_table_name, table_name)
      end
    end

    def create_table_like(like_table, table, &blk)
      code = table_schema_code(like_table)
      code.gsub!(/create_table\s+"#{like_table}"/, "create_table :#{table}")
      code.gsub!(/add_index\s+"#{like_table}"/, "add_index :#{table}")
      class_eval(code)
      change_table(table, &blk) if blk
      true
    end

    private

    def table_schema_code(table)
      dumper = ActiveRecord::SchemaDumper.send(:new, connection)
      stream = StringIO.new
      dumper.table(table.to_s,stream)
      stream.rewind
      code = stream.read
    end

    def disable_indexes(table)
      list = connection.indexes(table)
      list.each do |i|
        remove_index table, :name => i.name
      end
    end

    def enable_indexes(table, list)
      list.each do |i|
        options = {}
        options[:name]    = i.name    if i.name
        options[:length]  = i.lengths if i.lengths
        options[:unique]  = i.unique  if i.unique
        add_index table, i.columns, options
      end
    end
  end
end

::ActiveRecord::Migration.send :include, FastChangeTable