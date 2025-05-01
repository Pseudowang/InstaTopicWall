module ApplicationHelper
  # 代理图片路径帮助方法
  # 用法: proxy_image_path(url: "https://example.com/image.jpg")
  def proxy_image_path(url:)
    proxy_image_path = url.present? ? "#{request.base_url}/proxy_image?url=#{URI.encode_www_form_component(url)}" : nil
    proxy_image_path
  end
end
