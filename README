Use fast_change_table instead of change_table in your migrations on large tables of data. Uses a duplication pattern to speed things up.

# Known issues
- Not tested

uses ordinary change_table syntax but adds two options
- "replace_keys" to remove all indexes; new indexes will be specified
- "disable_keys" to remove indexes and apply them after data load; this is a tremendous performance enhancement for a dbms with fast index creation

other methods:

create_table_like(orignal_table, table_to_copy_to)
  creates a table with the same structure
  
disable_indexes(table)
  removes all indexes from a table, returns a list of index objects removed
  
enable_indexes(table, list_of_indexes)
  restores a list of indexes to a table
  
fast_add_indexes(table, &block)
  allows you to pass a block to add indexes.  For mysql creates specified indexes in one statement; allows the data to be scanned once.
  example
  
  fast_add_indexes :sometable do |t|
    t.index :some_column
    t.index [:some_other_column, :column_three], :name => "a_multicolumn_index"
  end
  
copy_table(from_table, to_table, remaps = [])
  copies rows from one table into another.  this probably only works with Mysql.
  by default copies data from column of from_table to to_table of same name.
  will not copy data where there is no corresponding column.
  the remaps argument can be supplied to tell copy table how to handle unmatched columns or override this behavior
  examples
  
  copy_table(old_users_without_email_hash, new_table, ['MD5(email)', 'email_hash'])
  
  copy_table(old_users_without_total, new_table, ['sum(payments)', 'total_payments'])