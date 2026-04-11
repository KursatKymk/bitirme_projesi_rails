class Credential < ApplicationRecord
  belongs_to :campaign, optional: true
  belongs_to :target,   optional: true

  validates :email, presence: true
  before_validation { self.captured_at ||= Time.current }

  # Demo amaçlı masked gösterim — tam şifre admin paneline düşmesin
  def masked_password
    return "" if password.blank?
    "#{password[0]}#{"•" * [password.length - 2, 1].max}#{password[-1]}"
  end
end
