class CreateEmailEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :email_events do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :target,   null: false, foreign_key: true
      t.string  :event_type,  null: false   # sent / opened / clicked / submitted
      t.string  :ip_address
      t.string  :user_agent
      t.datetime :occurred_at

      t.timestamps
    end
    add_index :email_events, :event_type
  end
end
