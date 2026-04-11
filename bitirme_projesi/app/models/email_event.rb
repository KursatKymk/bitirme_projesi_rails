class EmailEvent < ApplicationRecord
  belongs_to :campaign
  belongs_to :target

  TYPES = %w[sent opened clicked submitted].freeze
  validates :event_type, inclusion: { in: TYPES }

  before_validation { self.occurred_at ||= Time.current }

  scope :sent,      -> { where(event_type: "sent") }
  scope :opened,    -> { where(event_type: "opened") }
  scope :clicked,   -> { where(event_type: "clicked") }
  scope :submitted, -> { where(event_type: "submitted") }
end
