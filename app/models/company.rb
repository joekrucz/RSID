class Company < ApplicationRecord
  has_many :grant_applications, dependent: :nullify
  has_many :rnd_claims, dependent: :nullify
end
