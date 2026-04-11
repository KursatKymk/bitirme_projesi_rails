# ---------------------------------------------------------------------------
# PhishingMailer — main.py'deki send_email() fonksiyonunun Rails karşılığı.
# Dev ortamında letter_opener sayesinde tarayıcıda preview açılır,
# gerçekten outbound mail gitmez.
# ---------------------------------------------------------------------------
class PhishingMailer < ApplicationMailer
  def campaign_email
    @campaign = params[:campaign]
    @target   = params[:target]
    @link     = auth_with_token_url(@target.token, host: "localhost", port: 3000)

    mail(
      to:      @target.email,
      from:    @campaign.sender_email,
      subject: @campaign.email_subject.presence || "Acil Durum: Hesabınızı Doğrulayın"
    )
  end
end
