class InstagramService
  require "uri"
  require "net/http"
  require "json"

  API_KEY = ENV["TIKHUB_API_KEY"]

  def self.fetch_posts
    url = URI("https://api.tikhub.io/api/v1/instagram/web_app/fetch_hashtag_posts_by_keyword?keyword=GitHub")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url)

    request["Authorization"] = "Bearer #{API_KEY}"
    request["Accept"] = "application/json"

    response = http.request(request)

    if response.code.to_i == 200
      puts "API 调用成功！"
      puts response.read_body.force_encoding("UTF-8")
    else
      puts "API 调用失败，响应码：#{response.code}"
      puts response.read_body
    end
  end
end
