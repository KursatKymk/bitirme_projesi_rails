class CreateTargets < ActiveRecord::Migration[8.0]
  def change
    create_table :targets do |t|
      t.string :email,      null: false
      t.string :full_name
      t.string :group_name                  # undergraduate / graduate / staff
      t.string :token                       # kampanya linkinde kullanılan tekil token

      t.timestamps
    end
    add_index :targets, :email,  unique: true
    add_index :targets, :token,  unique: true
  end
end
