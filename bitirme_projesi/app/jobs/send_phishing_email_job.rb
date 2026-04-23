class SendPhishingEmailJob < ApplicationJob
  queue_as :default

  def perform(campaign_id, target_id)
    campaign = Campaign.find_by(id: campaign_id)
    target = Target.find_by(id: target_id)
    return unless campaign && target

    ct = campaign.campaign_targets.find_by(target: target)
    return unless ct

    # Yüksek SCL skoruna sahipse gönderme ve engellendi olarak işaretle
    if ct.spam_score.to_i >= 5
      EmailEvent.create!(campaign: campaign, target: target, event_type: "blocked_by_spam_filter")
      return
    end

    # Güvenli ise gönder
    begin
      PhishingMailer.with(campaign: campaign, target: target).campaign_email.deliver_now
      EmailEvent.create!(campaign: campaign, target: target, event_type: "sent")
      
      # Kampanya istatistiklerini güncelle (Thread-safe increment)
      Campaign.increment_counter(:emails_sent, campaign.id)
    rescue => e
      Rails.logger.error "Teslimat hatası: #{e.message}"
    end
  end
end
