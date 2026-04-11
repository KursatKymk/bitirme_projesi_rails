module Admin
  class CampaignsController < BaseController
    before_action :set_campaign, only: %i[show edit update destroy send_now]

    def index
      @campaigns = Campaign.recent
    end

    def show; end

    def new
      @campaign = Campaign.new(
        name: "Yeni Kampanya",
        sender_email: "registration@khas.edu.tr",
        scenario_prompt: "Create a highly plausible enrollment failure email to undergraduate students with a 'waitlisted' status, asking them to immediately verify their details via a secure portal to prevent course cancellation. Emphasize urgency and professional tone."
      )
    end

    def create
      @campaign = Campaign.new(campaign_params)
      if @campaign.save
        redirect_to admin_campaign_path(@campaign), notice: "Kampanya oluşturuldu."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @campaign.update(campaign_params)
        redirect_to admin_campaign_path(@campaign), notice: "Kampanya güncellendi."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @campaign.destroy
      redirect_to admin_campaigns_path, notice: "Kampanya silindi."
    end

    # POST /admin/campaigns/:id/send_now
    def send_now
      targets = Target.all
      targets = targets.where(group_name: @campaign.target_group) unless @campaign.target_group == "all"

      targets.find_each do |target|
        PhishingMailer.with(campaign: @campaign, target: target).campaign_email.deliver_now
        EmailEvent.create!(campaign: @campaign, target: target, event_type: "sent")
      end

      @campaign.update!(
        status: "sent",
        sent_at: Time.current,
        emails_sent: @campaign.emails_sent + targets.count
      )

      redirect_to admin_campaign_path(@campaign),
                  notice: "#{targets.count} hedefe letter_opener üzerinden mail açıldı."
    end

    private

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:name, :target_group, :sender_email,
                                       :prompt_type, :scenario_prompt,
                                       :email_subject, :email_body)
    end
  end
end
