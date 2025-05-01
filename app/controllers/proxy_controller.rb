class ProxyController < ApplicationController
  require 'open-uri'
  require 'digest'
  
  # 跳过 CSRF 验证，因为这是一个 API 端点
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  
  def image
    begin
      # 从参数中获取图片URL
      image_url = params[:url]
      
      # 验证URL
      return head :bad_request unless image_url.present?
      
      # 解码URL
      decoded_url = URI.decode_www_form_component(image_url)
      
      # 添加CORS头
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, Origin, Accept"
      response.headers["Access-Control-Expose-Headers"] = "Content-Type, Content-Length, Cache-Control"
      response.headers["Access-Control-Max-Age"] = "86400" # 24小时
      response.headers["Vary"] = "Origin"
      
      # 如果是预检请求，立即返回
      if request.method == "OPTIONS"
        return head :ok
      end
      
      # 创建缓存键（URL的MD5哈希值）
      cache_key = "proxy_image_#{Digest::MD5.hexdigest(decoded_url)}"
      
      # 尝试从缓存中获取图片
      cached_data = Rails.cache.read(cache_key)
      
      if cached_data.present?
        # 如果有缓存，直接从缓存返回
        Rails.logger.info("从缓存返回图片: #{decoded_url}")
        response.headers["Content-Type"] = cached_data[:content_type]
        response.headers["Cache-Control"] = "public, max-age=86400" # 缓存24小时
        response.headers["X-Cache"] = "HIT"
        
        return render plain: cached_data[:content]
      end
      
      # 没有缓存，设置超时以避免挂起
      content = nil
      content_type = nil
      
      # 增强浏览器请求头伪装
      headers = {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
        "Accept" => "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
        "Referer" => "https://www.instagram.com/",
        "Accept-Language" => "en-US,en;q=0.9",
        "Accept-Encoding" => "gzip, deflate, br",
        "Connection" => "keep-alive",
        "Sec-Fetch-Dest" => "image",
        "Sec-Fetch-Mode" => "no-cors",
        "Sec-Fetch-Site" => "cross-site",
        "Cache-Control" => "no-cache",
        "Pragma" => "no-cache",
        "DNT" => "1",
        :read_timeout => 15,
        :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE
      }
      
      # 记录请求尝试
      Rails.logger.info("尝试获取图片: #{decoded_url}")
      
      URI.open(decoded_url, headers) do |f|
        content_type = f.content_type
        content = f.read
        
        # 记录读取结果
        Rails.logger.info("成功读取图片内容，大小: #{content.bytesize} 字节")
        
        # 如果内容为空，退出
        if content.nil? || content.empty?
          Rails.logger.error("图片内容为空")
          render json: { error: "图片内容为空" }, status: :no_content
          return
        end
        
        # 缓存图片内容和内容类型，缓存时间设为1天
        Rails.cache.write(cache_key, { content: content, content_type: content_type }, expires_in: 1.day)
        
        # 设置响应头
        response.headers["Content-Type"] = content_type
        response.headers["Cache-Control"] = "public, max-age=86400" # 缓存24小时
        response.headers["X-Cache"] = "MISS"
      end
      
      render plain: content
    rescue OpenURI::HTTPError => e
      Rails.logger.error("图片代理HTTP错误: #{e.message} 对于URL: #{decoded_url}")
      status_code = e.respond_to?(:io) && e.io.respond_to?(:status) ? e.io.status[0].to_i : 500
      render json: { error: "无法获取图片: #{e.message}", url: decoded_url }, status: status_code
    rescue StandardError => e
      Rails.logger.error("图片代理错误: #{e.message}")
      Rails.logger.error("图片URL: #{decoded_url}")
      Rails.logger.error("完整错误: #{e.backtrace.join("\n")}")
      render json: { error: "处理图片时出错: #{e.message}", url: decoded_url }, status: :internal_server_error
    end
  end
  
  # 清除图片缓存的API
  def clear_cache
    if params[:url].present?
      # 如果提供了URL，只清除该URL的缓存
      decoded_url = URI.decode_www_form_component(params[:url])
      cache_key = "proxy_image_#{Digest::MD5.hexdigest(decoded_url)}"
      Rails.cache.delete(cache_key)
      Rails.logger.info("已清除图片缓存: #{decoded_url}")
      
      render json: { status: "success", message: "已清除指定URL的缓存" }
    elsif params[:clear_all] == "true"
      # 清除所有的图片缓存
      # 注意：这种方法可能不适用于所有缓存存储，特别是在生产环境中
      # 在生产环境中，可能需要根据具体缓存存储的API来实现
      if Rails.cache.is_a?(ActiveSupport::Cache::MemoryStore)
        Rails.cache.clear
        Rails.logger.info("已清除所有图片缓存")
        render json: { status: "success", message: "已清除所有缓存" }
      else
        # 对于其他类型的缓存存储，可能需要不同的实现
        render json: { status: "error", message: "当前缓存存储不支持此操作" }, status: :unprocessable_entity
      end
    else
      render json: { status: "error", message: "必须提供url参数或clear_all=true参数" }, status: :bad_request
    end
  end
end