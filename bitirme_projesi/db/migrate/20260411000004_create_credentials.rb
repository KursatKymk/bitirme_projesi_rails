class CreateCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :credentials do |t|
      t.references :campaign, foreign_key: true
      t.references :target,   foreign_key: true
      t.string :email
      t.string :password       # demo/bitirme için düz metin — ÜRETİMDE ASLA
      t.string :ip_address
      t.string :user_agent
      t.datetime :captured_at

      t.timestamps
    end
  end
end
