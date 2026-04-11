class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.string  :name,           null: false
      t.string  :target_group,   default: "all"           # all / graduate / staff
      t.string  :sender_email,   default: "registration@khas.edu.tr"
      t.string  :prompt_type,    default: "urgency"       # urgency / authority / curiosity
      t.text    :scenario_prompt
      t.text    :email_subject
      t.text    :email_body
      t.string  :status, default: "draft"                  # draft / sent / archived
      t.integer :emails_sent,   default: 0
      t.integer :emails_opened, default: 0
      t.integer :links_clicked, default: 0
      t.integer :creds_captured, default: 0
      t.datetime :sent_at

      t.timestamps
    end
    add_index :campaigns, :status
  end
end
