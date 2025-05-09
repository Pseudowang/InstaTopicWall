class Post < ApplicationRecord
  belongs_to :topic

  validates :instagram_id, presence: true, uniqueness: true
  validates :media_url, presence: true
  validates :timestamp, presence: true
  validates :id_prefile, presence: true

  def id_prefile=(value)
    if value.blank? && instagram_id.present? # 如果值为空且instagram_id存在
      write_attribute(:id_prefile, "ig_#{instagram_id}")
    else
      write_attribute(:id_prefile, value)
    end
  end
end
