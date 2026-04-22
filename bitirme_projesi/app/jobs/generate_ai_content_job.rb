class GenerateAiContentJob < ApplicationJob
  queue_as :default

  def perform(campaign_id, host, port)
    campaign = Campaign.find(campaign_id)
    return unless campaign

    campaign.reload
    targets = campaign.campaign_targets
    total = targets.count
    
    puts ">>> [AI JOB] Processing Campaign ID: #{campaign_id}"
    puts ">>> [AI JOB] Target Count: #{total}"

    if total == 0
      campaign.update!(ai_status: 'completed', ai_processed_count: 0)
      broadcast_progress(campaign, "No targets found to process.")
      return
    end

    campaign.update!(ai_status: 'processing', ai_total_count: total, ai_processed_count: 0)
    gemini = GeminiService.new

    targets.find_each.with_index(1) do |ct, index|
      begin
        puts ">>> [AI JOB] Generating content for: #{ct.target.email} (#{index}/#{total})"
        
        # Update UI: Start processing target
        campaign.update!(ai_processed_count: index)
        broadcast_progress(campaign, "Synthesizing: #{ct.target.email}")

        link = Rails.application.routes.url_helpers.auth_with_token_url(
          token: ct.target.token, 
          host: host, 
          port: port
        )

        ai_data = gemini.generate_personalized_email(campaign, ct.target, link)
        spam_eval = gemini.evaluate_spam_score(ai_data['subject'], ai_data['body'])

        ct.update!(
          personalized_subject: ai_data['subject'],
          personalized_body: ai_data['body'],
          spam_score: spam_eval['score'],
          spam_analysis: spam_eval['analysis']
        )
        puts ">>> [AI JOB] SUCCESS: #{ct.target.email}"
      rescue => e
        puts ">>> [AI JOB] ERROR for #{ct.target.email}: #{e.message}"
      end
    end

    campaign.update!(ai_status: 'completed')
    broadcast_progress(campaign, "Generation complete.")
    puts ">>> [AI JOB] FINISHED"
    
    # Kendi kendine yenileme döngüsüne girmemesi için durumu temizle
    # (Tarayıcıya broadcast ulaştıktan sonra db'de durumu sıfırlıyoruz)
    sleep(2)
    campaign.update!(ai_status: 'idle', ai_processed_count: 0)
  end

  private

  def broadcast_progress(campaign, current_target_email)
    total = campaign.ai_total_count.to_i
    total = 1 if total == 0 # Avoid ZeroDivisionError
    percentage = ((campaign.ai_processed_count.to_f / total) * 100).round
    
    Turbo::StreamsChannel.broadcast_replace_to(
      campaign,
      target: "ai_generation_modal_content",
      partial: "admin/campaigns/ai_progress",
      locals: { 
        campaign: campaign, 
        percentage: percentage, 
        current_email: current_target_email,
        is_live: true
      }
    )
  end
end
