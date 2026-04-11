class Target < ApplicationRecord
  has_many :email_events, dependent: :destroy
  has_many :credentials,  dependent: :nullify

  GROUPS = %w[undergraduate graduate staff].freeze

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :group_name, inclusion: { in: GROUPS }, allow_nil: true

  before_validation :ensure_token, on: :create

  private

  def ensure_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end
end
