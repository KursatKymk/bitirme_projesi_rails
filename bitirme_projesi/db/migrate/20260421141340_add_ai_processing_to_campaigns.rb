class AddAiProcessingToCampaigns < ActiveRecord::Migration[8.0]
  def change
    add_column :campaigns, :ai_status, :string
    add_column :campaigns, :ai_processed_count, :integer
    add_column :campaigns, :ai_total_count, :integer
  end
end
