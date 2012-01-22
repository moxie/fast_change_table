module ActiveRecord
  module ConnectionAdapters #:nodoc:
    
    module SchemaStatements
      def change_table_with_remaps(table_name)
        t = Table.new(table_name, self)
        yield t
        return t.renamed_columns
      end
    end
    
    class Table
      
      def initialize(table_name, base)
        @table_name = table_name
        @base = base
        @renamed_columns = []
      end
      
      def renamed_columns
        @renamed_columns
      end
      
      def rename(column_name, new_column_name)
        @renamed_columns << [column_name, new_column_name]
        @base.rename_column(@table_name, column_name, new_column_name)
      end
      
    end
  end
end

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
       create_table_like(old_table_name, table_name, options)
       renamed_columns = change_table_with_remaps(table_name, &block)
       index_list = options[:disable_keys]  ? disable_indexes(table_name) : []
       #prepare the columns names for the insert statements
       copy_table(old_table_name, table_name, renamed_columns)
       enable_indexes(table_name, index_list) if options[:disable_keys]
       drop_table(old_table_name)
      rescue Exception => e
        puts "#{e}\n#{e.backtrace}"
        drop_table(table_name) if table_exists?(table_name)
        rename_table(old_table_name, table_name)
        raise e
      end
    end

    def fast_add_indexes(table, &blk)
      phoney = PhoneyTable.new(table.to_s)
      yield phoney
      enable_indexes(table, phoney.indexes)
    end
    
    #create_table_like( :sometable, :newtable, :remove_keys => true)
    def create_table_like(like_table, table, options = {})
      options.symbolize_keys!
      code = table_schema_code(like_table)
      code.gsub!(/create_table\s+"#{like_table}"/, "create_table :#{table}")
      if options[:replace_keys] or options[:remove_keys]
        code.gsub!(/add_index\s+"#{like_table}"/, "#add_index :#{table}")
      else
        code.gsub!(/add_index\s+"#{like_table}"/, "add_index :#{table}")
      end
      class_eval(code)
      true
    end

    #copy_table( :sometable, :newtable, [[:old_column, :new_column]])
    def copy_table(from, to, remaps = [])
      old = connection.columns(from).collect(&:name)
      current = connection.columns(to).collect(&:name)
      remapped_columns = remaps.collect {|c| c.first.to_s}.compact
      common = (current & old).sort - remapped_columns
      from_columns = common.collect {|c| "`#{c}`"}
      to_columns = common.collect {|c| "`#{c}`"}
      remaps.each do |remap|
        remap = [remap].flatten
        next if remap.length != 2
        from_columns << remap.first
        to_columns << remap.last
      end
      from_columns_to_s = from_columns.join(', ')
      to_columns_to_s   = to_columns.join(', ')
      execute "INSERT INTO #{to}(#{to_columns_to_s}) SELECT #{from_columns_to_s} FROM #{from}"
    end

    def table_schema_code(table)
      dumper = ActiveRecord::SchemaDumper.send(:new, connection)
      stream = StringIO.new
      dumper.send(:table, table.to_s, stream)
      stream.rewind
      code = stream.read
    end

    #removes all the indexes 
    def disable_indexes(table)
      list = connection.indexes(table)
      list.each do |i|
        remove_index table, :name => i.name
      end
      list
    end

    #
    def enable_indexes(table, list)
      list.each do |i|
        options = {}
        options[:name]    = i.name    if i.name
        options[:length]  = i.lengths if i.lengths
        options[:unique]  = i.unique  if i.unique
        add_index table, i.columns, options
      end
      true
    end

    class PhoneyTable

      attr_accessor :indexes

      def initialize(tablename)
        @table = tablename
        @indexes = []
      end

      def index(columns, options = {})
        new_index = PhoneyIndex.new(@table, columns, options)
        @indexes << new_index unless @indexes.to_a.any? {|i| i == new_index}
      end

      def indexes; @indexes.to_a.uniq end
    end

    class PhoneyIndex

      attr_accessor :columns, :lengths, :name, :unique

      def initialize(table, cols, options)
        cols = [cols].flatten
        self.columns = cols.collect(&:to_s)
        self.lengths = options[:length]
        self.unique = !!options[:unique]
        self.name = options[:name] || "index_#{table}_on_#{columns.join('_and_')}"
        self.name = "#{columns.join('_')}_idx" if name.length > 64
      end

      def ==(val)
        columns == val.columns rescue false
      end
    end
  end
end

::ActiveRecord::Migration.send :include, FastChangeTable