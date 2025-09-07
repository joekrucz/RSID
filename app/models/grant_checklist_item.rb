class GrantChecklistItem < ApplicationRecord
  belongs_to :grant_application

  validates :section, presence: true
  validates :title, presence: true
end
