class InstagramService
  require "uri"
  require "net/http"
  require "json"
  require "securerandom" # 用于生成随机 UUID
  require "openssl" # 用于SSL证书验证

  API_KEY = ENV["TIKHUB_API_KEY"]

  def self.get_posts_by_hashtag(hashtag, limit = 20, feed_type = "recent")
    Rails.logger.info("开始查询标签 #{hashtag} 的帖子，类型: #{feed_type}")
    url = URI("https://api.tikhub.io/api/v1/instagram/web_app/fetch_hashtag_posts_by_keyword?keyword=#{URI.encode_www_form_component(hashtag)}&feed_type=#{feed_type}")
    Rails.logger.info("请求URL: #{url}")

    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER # 确保SSL证书验证
    request = Net::HTTP::Get.new(url)

    request["Authorization"] = "Bearer #{API_KEY}"
    request["Accept"] = "application/json"

    begin
      Rails.logger.info("正在发送请求到TikHub API...")
      response = https.request(request)
      Rails.logger.info("收到响应，状态码: #{response.code}")

      if response.is_a?(Net::HTTPSuccess)
        # 确保响应体使用 UTF-8 编码
        response_body = response.body.force_encoding('UTF-8')
        data = JSON.parse(response_body)
        Rails.logger.info("响应数据解析成功")

        posts_data = nil # 初始化帖子数据
        # 尝试多种可能的数据路径
        if data["code"] && data["data"]
          if data["data"]["data"] && data["data"]["data"]["items"] && data["data"]["data"]["items"].is_a?(Array)
            posts_data = data["data"]["data"]["items"]
            Rails.logger.info("在data.data.items数组中找到#{posts_data.size}个帖子")
          elsif data["data"]["items"] && data["data"]["items"].is_a?(Array)
            posts_data = data["data"]["items"]
            Rails.logger.info("在data.items数组中找到#{posts_data.size}个帖子")
          end
        end

        if posts_data && posts_data.any?
          Rails.logger.info("找到#{posts_data.size}个帖子数据")
          Rails.logger.debug("第一个帖子的结构: #{posts_data.first.keys}")
          parsed_posts = parse_posts(posts_data, hashtag) # 解析帖子数据
          Rails.logger.info("成功解析#{parsed_posts.size}个帖子")
          return parsed_posts  # 显式返回解析后的帖子数组
        end

        Rails.logger.warn("未找到预期格式的数据，将使用模拟数据")
        mock_posts(hashtag)
      else
        Rails.logger.error("HTTP 请求失败，状态码: #{response.code}")
        Rails.logger.info("响应内容: #{response.body}")
        mock_posts(hashtag)
      end
    rescue => e
      Rails.logger.error("Instagram API 错误: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      mock_posts(hashtag)
    end
  end


  private

  def self.parse_posts(data, hashtag)
    return [] unless data.is_a?(Array) # 确保数据是数组

    Rails.logger.info("正在解析来自 API 响应的 #{data.size} 个帖子")

    data.map do |post|
      Rails.logger.debug("帖子数据结构: #{post.keys}")

      # 提取 Instagram ID，优先使用 id, pk, code；没有则生成 UUID
      instagram_id = post["id"] || post["pk"] || post["code"] || SecureRandom.uuid

      # 提取媒体 URL，尝试获取 image_versions 中的最佳图片
      media_url = if post.dig("image_versions", "items")&.any?
                    best_image = post["image_versions"]["items"].max_by { |img| img["width"].to_i * img["height"].to_i }
                    best_image["url"]
      elsif post["thumbnail_url"]
                    post["thumbnail_url"]
      elsif post["media_url"]
                    post["media_url"]
      else
                    nil
      end

      # 确保媒体 URL 使用 HTTPS（如果需要的话）
      media_url = media_url.gsub(/^http:/, "https:") if media_url.present?

      # 提取帖子描述，若不存在使用默认描述
      caption_text = if post.dig("caption", "text")
                       post["caption"]["text"]
      else
                       "Post about ##{hashtag}"
      end

      # 提取用户名：可能在 user 或 caption.user 中
      username = if post.dig("user", "username")
                   post["user"]["username"]
      elsif post.dig("caption", "user", "username")
                   post["caption"]["user"]["username"]
      else
                   "instagram_user"
      end

      # 提取用户头像 URL
      profile_pic = post.dig("user", "profile_pic_url") || default_profile_image

      # 处理时间戳
      timestamp = if post["taken_at_date"]
                    post["taken_at_date"]
      elsif post["taken_at"]
                    Time.at(post["taken_at"]).utc.to_s
      else
                    Time.current.to_s
      end

      {
        instagram_id: instagram_id,
        media_type: post["media_type"] || 1,  # 1 表示图片
        media_url: media_url,
        permalink: post["permalink"] || (post["code"] && "https://instagram.com/p/#{post['code']}") || "https://instagram.com/p/unknown",
        caption: caption_text,
        username: username,
        timestamp: timestamp,
        profile_picture_url: profile_pic,
        id_prefile: "ig_#{instagram_id}"
      }
    end
  end

  # 生成模拟帖子数据，当API调用失败时使用
  def self.mock_posts(hashtag)
    Rails.logger.info("为标签 #{hashtag} 生成模拟帖子")

    5.times.map do |i|
      {
        instagram_id: "mock_#{i}_#{Time.now.to_i}",
        media_type: "IMAGE",
        media_url: nil, # 不使用默认图片
        permalink: "https://instagram.com/p/mock#{i}",
        caption: "这是关于 ##{hashtag} 的模拟帖子，用于API不可用时测试。",
        username: "mock_user_#{i}",
        timestamp: (Time.current - i.hours).to_s,
        profile_picture_url: nil, # 不使用默认图片
        id_prefile: "ig_mock_#{i}_#{Time.now.to_i}" # 添加模拟的id_prefile
      }
    end
  end

  # 添加default_profile_image方法
  def self.default_profile_image
    nil # 返回nil而不是占位图URL
  end
end
