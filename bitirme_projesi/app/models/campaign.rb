class Campaign < ApplicationRecord
  has_many :email_events, dependent: :destroy
  has_many :credentials,  dependent: :nullify
  has_many :campaign_targets, dependent: :destroy
  has_many :targets, through: :campaign_targets

  attr_accessor :import_mode, :file # Virtual attributes for the form

  TARGET_GROUPS = %w[all graduate staff].freeze # Still referenced in some legacy code but we'll phase out
  PROMPTS       = %w[urgency authority curiosity].freeze
  STATUSES      = %w[draft sent archived].freeze
  LANGUAGES     = %w[English Turkish].freeze

  validates :name, presence: true
  validates :prompt_type,  inclusion: { in: PROMPTS }
  validates :status,       inclusion: { in: STATUSES }
  validates :email_language, inclusion: { in: LANGUAGES }, allow_nil: true

  # Set defaults
  after_initialize :set_defaults, if: :new_record?

  scope :recent, -> { order(created_at: :desc) }

  def set_defaults
    self.email_language ||= "English"
    self.use_custom_scenario = false if self.use_custom_scenario.nil?
    self.prompt_type ||= "urgency"
  end

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

  def target_headers
    ['email', 'full name', 'role', 'department']
  end
end
