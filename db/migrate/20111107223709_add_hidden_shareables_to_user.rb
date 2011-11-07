class AddHiddenShareablesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :hidden_shareables, :string, :default => {}.to_yaml
  end

  def self.down
    remove_column :users, :hidden_shareables
  end
end
