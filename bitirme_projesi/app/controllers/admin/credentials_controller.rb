module Admin
  class CredentialsController < BaseController
    def index
      @credentials = Credential.includes(:campaign, :target).order(captured_at: :desc).limit(200)
    end
  end
end
