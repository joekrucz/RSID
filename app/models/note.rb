class Note < ApplicationRecord
  belongs_to :user
  
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :content, presence: true
  validates :user, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  
  # Search scope
  scope :search_by_content, ->(query) {
    where("title LIKE ? OR content LIKE ?", "%#{query}%", "%#{query}%")
  }
  
  # Sort scope
  scope :sorted_by, ->(field, direction = 'ASC') {
    case field
    when 'title'
      order("title #{direction.upcase}")
    when 'updated_at'
      order("updated_at #{direction.upcase}")
    else
      order("created_at #{direction.upcase}")
    end
  }
  
  # Class method for complex filtering and sorting
  def self.filtered_and_sorted(user, search: nil, sort_by: 'created_at', sort_order: 'DESC')
    notes = by_user(user)
    
    notes = notes.search_by_content(search) if search.present?
    notes.sorted_by(sort_by, sort_order)
  end
  
  # Global search method
  def self.search_global(query, current_user)
    base_query = if current_user.admin?
                   all
                 elsif current_user.employee?
                   all
                 else
                   where(user: current_user)
                 end
    
    base_query.where("title LIKE ? OR content LIKE ?", "%#{query}%", "%#{query}%")
  end
  

end
