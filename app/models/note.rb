class Note < ApplicationRecord
  belongs_to :user
  
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :content, presence: true
  validates :user, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  
  def created_at_formatted
    created_at.strftime("%B %d, %Y")
  end
  
  def updated_at_formatted
    updated_at.strftime("%B %d, %Y")
  end
end
