require 'spec_helper'

describe ActiveRecord::Migration do
  before(:each) do
    ActiveRecord::Migration.create_table :my_table, :force => true do |t|
      t.integer :an_integer
      t.string :a_string
      t.string :a_name
    end
    @connection = ActiveRecord::Migration.connection
  end
  
  after(:each) do
    ActiveRecord::Migration.drop_table(:my_copied_table) rescue nil
  end

  describe "initialize table" do
    it "should have expected starting table" do
      @connection.columns("my_table").all? do |c| 
        ["id", "an_integer", "a_string", "a_name"].include?(c.name)
      end.should eq(true)
    end
  end
    
  describe "#create_table_like" do
    it "should create an identical table" do
      ActiveRecord::Migration.create_table_like(:my_table, :my_copied_table)
      
      @connection.columns("my_copied_table").all? do |c| 
        ["id", "an_integer", "a_string", "a_name"].include?(c.name.to_s)
      end.should eq(true)
    end
  end
  
  describe "#fast_add_indexes, #disable_indexes, #enable_indexes" do
    it "should add index, remove it then put it back" do
      ActiveRecord::Migration.fast_add_indexes :my_table do |t|
        t.index :an_integer, :name => "an_index"
      end
      @connection.indexes("my_table").collect(&:name).include?("an_index").should eq(true)
      
      indexes = ActiveRecord::Migration.disable_indexes("my_table")
      @connection.indexes("my_table").collect(&:name).include?("an_index").should eq(false)
      
      ActiveRecord::Migration.enable_indexes("my_table", indexes)
      @connection.indexes("my_table").collect(&:name).include?("an_index").should eq(true)
    end
  end
  
  describe "#copy_table" do
    it "should copy the records from one table to another" do
      @connection.execute "INSERT my_table (an_integer, a_string, a_name) VALUES (1,'String','Name')"
      ActiveRecord::Migration.create_table_like(:my_table, :my_copied_table)
      ActiveRecord::Migration.add_column(:my_copied_table, :new_column, :string)
      ActiveRecord::Migration.copy_table(:my_table, :my_copied_table, [["'Nothing'", "new_column"]])
      record = @connection.select_all("select * from my_copied_table").first
      record['an_integer'].should eq(1)
      record['a_string'].should eq('String')
      record['a_name'].should eq('Name')
      record['new_column'].should eq('Nothing')
    end
  end
  
  describe "#fast_change_table" do
    it "should bring it all together" do
      @connection.execute "INSERT my_table (an_integer, a_string, a_name) VALUES (1,'String','Name')"
      ActiveRecord::Migration.add_index :my_table, :an_integer, :name => "an_index"
      ActiveRecord::Migration.fast_change_table :my_table, :remove_keys => true do |t|
        t.change :an_integer, :integer
        t.change :a_string, :string
        t.change :a_name, :string
        t.string :new_column
      end
      record = @connection.select_all("select * from my_table").first
      record['an_integer'].should eq(1)
      record['a_string'].should eq('String')
      record['a_name'].should eq('Name')
      record['new_column'].should eq(nil)
      @connection.indexes("my_table").empty?.should eq(true)
    end
  end
end

