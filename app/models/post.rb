require 'date'
class Post < ApplicationRecord
  belongs_to :topic

  validates :instagram_id, presence: true, uniqueness: true
  validates :media_url, presence: true
  validates :timestamp, presence: true
  validates :id_prefile, presence: true

  def timestamp=(value)
    if value.is_a?(String)
      write_attribute(:timestamp, DataTime.parse(value))
  
end
