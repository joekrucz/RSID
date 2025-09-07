class Company < ApplicationRecord
  has_many :grant_applications, dependent: :nullify
end
