module Admin
  class DashboardController < BaseController
    def index
      @total_emails_sent = Campaign.sum(:emails_sent)
      @total_clicks      = Campaign.sum(:links_clicked)
      @total_captured    = Campaign.sum(:creds_captured)

      @ctr = @total_emails_sent.zero? ? 0.0 :
               (@total_clicks.to_f / @total_emails_sent * 100).round(1)

      @breach_rate = @total_emails_sent.zero? ? 0.0 :
               (@total_captured.to_f / @total_emails_sent * 100).round(1)

      @credential_submission_rate = @breach_rate
      @campaigns = Campaign.recent.limit(10)

      # Kampanya bazlı engagement (bar chart için)
      @engagement = Campaign.where(status: "sent").map do |c|
        { name: c.name, opened: c.emails_opened, clicked: c.links_clicked, captured: c.creds_captured }
      end
    end
  end
end
