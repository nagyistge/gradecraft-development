class AddStateAndCreatedByToBadges < ActiveRecord::Migration[5.0]
  def change
    add_column :badges, :state, :string, null: false, default: "proposed"
    add_column :badges, :created_by, :integer, null: true, default: false
    add_index :badges, :created_by
  end
end
