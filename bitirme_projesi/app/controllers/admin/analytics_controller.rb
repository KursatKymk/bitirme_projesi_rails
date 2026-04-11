module Admin
  class AnalyticsController < BaseController
    def index
      @campaigns = Campaign.where(status: "sent").recent
      @total_sent    = Campaign.sum(:emails_sent)
      @total_opened  = Campaign.sum(:emails_opened)
      @total_clicked = Campaign.sum(:links_clicked)
      @total_creds   = Campaign.sum(:creds_captured)

      @series = @campaigns.map do |c|
        {
          label: c.name,
          sent: c.emails_sent,
          opened: c.emails_opened,
          clicked: c.links_clicked,
          captured: c.creds_captured
        }
      end
    end
  end
end
