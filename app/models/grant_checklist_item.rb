class GrantChecklistItem < ApplicationRecord
  belongs_to :grant_application

  validates :section, presence: true
  validates :title, presence: true

  scope :for_section, ->(section) { where(section: section) }
end

class GrantChecklistItem < ApplicationRecord
  belongs_to :grant_application

  validates :section, presence: true
  validates :title, presence: true
end
