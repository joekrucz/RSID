class UserFeatureAccess < ApplicationRecord
  belongs_to :user
  belongs_to :feature_flag
  
  validates :user_id, uniqueness: { scope: :feature_flag_id }
end
