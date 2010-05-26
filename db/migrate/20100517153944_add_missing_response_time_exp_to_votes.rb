class AddMissingResponseTimeExpToVotes < ActiveRecord::Migration
  def self.up
	  add_column :votes, :missing_response_time_exp, :string, :default => ""
	  add_column :skips, :missing_response_time_exp, :string, :default => ""
  end

  def self.down
	  remove_column :votes, :missing_response_time_exp
	  remove_column :skips, :missing_response_time_exp
  end
end
