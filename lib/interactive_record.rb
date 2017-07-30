require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def initialize(options={})
    options.each do |key, val|
      self.send("#{key}=", val)
    end
  end

  def self.column_names
    sql = <<-SQL
      PRAGMA table_info(#{table_name})
    SQL
    columns = []
    newary = DB[:conn].execute(sql)
    newary.each do |row|
      columns << row["name"]
    end
    columns.compact
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    vals = []
    self.class.column_names.each do |col|
      vals << "'#{send(col)}'" unless send(col).nil?
    end
    vals.join(", ")
  end

  def table_name_for_insert
    self.class.table_name
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end



  def self.find_by(options)
    options.map do |key, val|
      sql = "SELECT * FROM #{self.table_name} WHERE #{key} = '#{val}'"
      DB[:conn].execute(sql).first
    end
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end


end
