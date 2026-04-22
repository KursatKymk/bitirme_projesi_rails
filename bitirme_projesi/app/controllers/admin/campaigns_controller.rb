module Admin
  class CampaignsController < BaseController
    before_action :set_campaign, only: %i[show edit update destroy send_now generate_ai_content add_target ai_status]

    def index
      @campaigns = Campaign.recent
    end

    def show; end

    def new
      @campaign = Campaign.new(
        name: "New Campaign",
        sender_email: "registration@khas.edu.tr",
        use_custom_scenario: false,
        scenario_prompt: "Create a highly plausible enrollment failure email to undergraduate students with a 'waitlisted' status..."
      )
    end

    def create
      @campaign = Campaign.new(campaign_params)
      if @campaign.save
        handle_excel_import if params[:campaign][:file].present?
        redirect_to edit_admin_campaign_path(@campaign), notice: "Campaign created successfully. You can now generate AI content."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      # Sonsuz yenileme döngüsünü kırmak için: Eğer durum 'completed' ise boşa al.
      if @campaign.ai_status == 'completed'
        @campaign.update(ai_status: 'idle')
      end
    end

    def update
      if @campaign.update(campaign_params)
        handle_excel_import if params[:campaign][:file].present?
        redirect_to edit_admin_campaign_path(@campaign), notice: "Campaign updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @campaign.destroy
      redirect_to admin_campaigns_path, notice: "Campaign deleted."
    end

    # POST /admin/campaigns/:id/send_now
    def send_now
      targets = @campaign.targets
      
      scheduled_time = params[:scheduled_time].presence
      
      targets.find_each do |target|
        if scheduled_time
          target_time = Time.zone.parse(scheduled_time)
          SendPhishingEmailJob.set(wait_until: target_time).perform_later(@campaign.id, target.id)
        else
          SendPhishingEmailJob.perform_later(@campaign.id, target.id)
        end
      end

      # Mark campaign as sent or scheduled
      status_label = scheduled_time ? "scheduled" : "sent"
      time_label   = scheduled_time ? Time.zone.parse(scheduled_time) : Time.current

      @campaign.update!(
        status: status_label,
        sent_at: time_label
      )

      if scheduled_time
        redirect_to admin_campaign_path(@campaign), notice: "#{targets.count} phishing targets scheduled for dispatch at #{scheduled_time}."
      else
        redirect_to admin_campaign_path(@campaign), notice: "Dispatch initiated for #{targets.count} targets in the background."
      end
    end

    # POST /admin/campaigns/:id/generate_ai_content
    def generate_ai_content
      @campaign.update!(ai_status: 'processing', ai_processed_count: 0)
      
      GenerateAiContentJob.perform_later(@campaign.id, request.host, request.port)

      respond_to do |format|
        format.html { redirect_to edit_admin_campaign_path(@campaign), notice: "AI Generation started in the background." }
        format.turbo_stream
      end
    end

    # GET /admin/campaigns/:id/ai_status
    def ai_status
      render json: {
        status: @campaign.ai_status,
        processed: @campaign.ai_processed_count.to_i,
        total: @campaign.ai_total_count.to_i
      }
    end

    # POST /admin/campaigns/:id/add_target
    def add_target
      email = params[:email].to_s.strip.downcase
      full_name = params[:full_name].to_s.strip
      role = params[:role].to_s.strip
      department = params[:department].to_s.strip

      if email.present?
        target = Target.find_or_initialize_by(email: email)
        target.full_name = full_name if full_name.present?
        target.save! if target.changed?

        campaign_target = CampaignTarget.find_or_initialize_by(campaign: @campaign, target: target)
        campaign_target.custom_data ||= {}
        campaign_target.custom_data['role'] = role
        campaign_target.custom_data['department'] = department
        campaign_target.save!

        redirect_to edit_admin_campaign_path(@campaign), notice: "Target '#{full_name}' added manually."
      else
        redirect_to edit_admin_campaign_path(@campaign), alert: "Email is required for manual entry."
      end
    end

    private

    def handle_excel_import
      # Handle Replace mode
      if params[:campaign][:import_mode] == "replace"
        @campaign.campaign_targets.destroy_all
      end

      # Run import
      file_path = params[:campaign][:file].path
      ExcelImportService.new(@campaign, file_path).import
    rescue => e
      flash[:alert] = "Import Error: #{e.message}"
    end

    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:name, :sender_email, :prompt_type, 
                                       :use_custom_scenario, :scenario_prompt,
                                       :email_language, :import_mode, :file)
    end
  end
end
