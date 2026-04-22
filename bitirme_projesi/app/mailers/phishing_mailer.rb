# ---------------------------------------------------------------------------
# PhishingMailer — main.py'deki send_email() fonksiyonunun Rails karşılığı.
# Dev ortamında letter_opener sayesinde tarayıcıda preview açılır,
# gerçekten outbound mail gitmez.
# ---------------------------------------------------------------------------
class PhishingMailer < ApplicationMailer
  helper :application

  def campaign_email
    @campaign = params[:campaign]
    @target   = params[:target]
    @link     = auth_with_token_url(token: @target.token)

    ct = CampaignTarget.find_by(campaign: @campaign, target: @target)
    @subject = ct&.personalized_subject.presence || @campaign.email_subject.presence || "Acil Durum: Hesabınızı Doğrulayın"
    @body    = ct&.personalized_body.presence || @campaign.email_body.presence

    mail(
      to:      @target.email,
      from:    @campaign.sender_email,
      subject: @subject
    )
  end
end
