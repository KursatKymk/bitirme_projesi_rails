class Campaign < ApplicationRecord
  has_many :email_events, dependent: :destroy
  has_many :credentials,  dependent: :nullify

  TARGET_GROUPS = %w[all graduate staff].freeze
  PROMPTS       = %w[urgency authority curiosity].freeze
  STATUSES      = %w[draft sent archived].freeze

  validates :name, presence: true
  validates :target_group, inclusion: { in: TARGET_GROUPS }
  validates :prompt_type,  inclusion: { in: PROMPTS }
  validates :status,       inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }

  # React tarafındaki KPI'larla birebir: CTR = clicks / sent
  def click_through_rate
    return 0.0 if emails_sent.zero?
    (links_clicked.to_f / emails_sent * 100).round(1)
  end

  def credential_submission_rate
    return 0.0 if emails_sent.zero?
    (creds_captured.to_f / emails_sent * 100).round(1)
  end

  def open_rate
    return 0.0 if emails_sent.zero?
    (emails_opened.to_f / emails_sent * 100).round(1)
  end
end
