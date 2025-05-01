class Post < ApplicationRecord
  belongs_to :topic

  validates :instagram_id, presence: true, uniqueness: true
  validates :media_url, presence: true
  validates :timestamp, presence: true
  validates :id_prefile, presence: true

  def timestamp=(value) # 验证时间戳是否有效
    if value.is_a?(String) # 如果是字符串
      write_attribute(:timestamp, DateTime.parse(value))
    else
      write_attribute(:timestamp, value) # 不是就直接赋值
    end

    rescue ArgumentError
      Rails.logger.error("Invalid timestamp format: #{value}")
      write_attribute(:timestamp, nil)
    rescue TypeError
      Rails.logger.error("Invalid timestamp type: #{value.class}")
      write_attribute(:timestamp, nil)
    rescue StandardError => e
      Rails.logger.error("Error parsing timestamp: #{e.message}")
      write_attribute(:timestamp, nil)
    end
    def id_prefile=(value)
      if value.blank? && instagram_id.present? # 如果值为空且instagram_id存在
        write_attribute(:id_prefile, "ig_#{instagram_id}")
      else
        write_attribute(:id_prefile, value)
      end
    end
end
