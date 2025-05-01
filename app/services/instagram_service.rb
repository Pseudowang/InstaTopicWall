class InstagramService
  require "uri"
  require "net/http"
  require "json"
  require "securerandom" # 用于生成随机 UUID

  API_KEY = ENV["TIKHUB_API_KEY"]

  def self.fetch_posts
    url = URI("https://api.tikhub.io/api/v1/instagram/web_app/fetch_hashtag_posts_by_keyword?keyword=pseudowangforfuntiontest")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)

    request["Authorization"] = "Bearer #{API_KEY}"
    request["Accept"] = "application/json"

    response = http.request(request)

    if response.code.to_i == 200 # 将检查响应码转换为整数进行比较
      puts "API 调用成功！"
      json = JSON.parse(response.read_body.force_encoding("UTF-8")) # 为了能够使用 dig
      name = json.dig("data", "data", "additional_data", "name") # 返回的是 hashtag 名

      posts = json.dig("data", "data", "items")
      if posts.is_a?(Array) # 判断items 是否是数组
        parsed_posts = parse_posts(posts)
      end
      parsed_posts  # 条件成立时返回解析后的帖子
    else
      puts "API 调用失败，响应码：#{response.code}"
      puts response.read_body.force_encoding("UTF-8")
      nil
    end
  rescue => e
    puts "Error: #{e.message}"
    nil
  end

  private

  def self.parse_posts(items) # 拆分response 的 items
    items.map do |item|
      # 使用 item["pk"] 作为 instagram_id，如果没有则 fallback 到 item["id"] 或随机 UUID
      instagram_id = item["pk"] || item["id"] || SecureRandom.uuid

      # 尝试从 image_versions 中获取媒体 URL
      media_url = if item.dig("image_versions", "items")&.any? # 是否有图片, 并且使用 any? 方法检查是否有图片
                    # 这里简单使用第一个图片 URL，小的图片一般是略所图
                    item["image_versions"]["items"].first["url"]
                  else
                    nil
                  end

      # 媒体类型，如图片可写 "IMAGE"，你也可直接存数字 1
      media_type = item["media_type"] || "IMAGE"

      # 如果返回中有 code 字段，则构造帖子链接
      permalink = if item["code"]
                    "https://instagram.com/p/#{item['code']}"
                  else
                    nil
                  end

      # 提取帖子文字内容，存在于 caption.text 中
      caption_text = item.dig("caption", "text") || ""

      # 获取用户名，可能在 caption.user 或者 item.user 下
      username = item.dig("caption", "user", "username") || item.dig("user", "username") || "instagram_user"

      # 时间戳：如果有 taken_at_date 字段，优先使用；否则使用当前时间
      timestamp = item["taken_at_date"] || Time.current.to_s

      # 获取用户头像 URL，从 user.profile_pic_url 获取
      profile_pic = item.dig("user", "profile_pic_url") || nil

      {
        instagram_id: instagram_id,
        media_type: media_type,
        media_url: media_url,
        permalink: permalink,
        caption: caption_text,
        username: username,
        timestamp: timestamp,
        profile_picture_url: profile_pic,
        id_prefile: "ig_#{instagram_id}"
      }
    end
  end
end