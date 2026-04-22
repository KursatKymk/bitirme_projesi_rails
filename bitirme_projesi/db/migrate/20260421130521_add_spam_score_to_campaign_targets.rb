class AddSpamScoreToCampaignTargets < ActiveRecord::Migration[8.0]
  def change
    add_column :campaign_targets, :spam_score, :integer
    add_column :campaign_targets, :spam_analysis, :text
  end
end
