class RndChecklistItem < ApplicationRecord
  belongs_to :rnd_claim

  validates :section, presence: true
  validates :title, presence: true

  scope :for_section, ->(section) { where(section: section) }
end
