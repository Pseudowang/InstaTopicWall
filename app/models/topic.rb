class Topic < ApplicationRecord # 将Topic 类转变为一个 ActiveRecord 模型
    validates :name, presence: true, uniqueness: true
    validates :hashtag, presence: true, uniqueness: true

    has_many :posts, dependent: :destroy

    def refresh_posts
        posts_data = InstagramService.get_posts_by_hashtag(hashtag)

        if posts_data.present?
            # 处理posts_data
            process_posts(posts_data)
            update(last_refreshed_at: Time.current)
        end
    # 如果posts_data为空，可能是因为没有新帖子，或者发生了错误
    # 在这种情况下，我们可以选择不更新last_refreshed_at
    rescue => e
        Rails.logger.error("Error refreshing posts for topic #{name}: #{e.message}")
        update(last_refreshed_at: Time.current) # 即使调用失败也要更新时间
    end

    private
    def process_posts(posts_data) # 通过hash 判断帖子是否存在, 在Ruby 中，hash 是一种数据结构，用于存储键值对。它类似于 Python 中的字典
        posts_data.each do |post_data|
            if post_data[:instagram_id].present? # 修正方法名称
                if !post_data[:id_prefile]
                    post_data[:id_prefile] = "ig_#{post_data[:instagram_id]}"
                end
                existing_post = posts.find_by(instagram_id: post_data[:instagram_id]) # 通过instagram_id查找现有帖子
                if existing_post
                    existing_post.update(post_data)
                else
                    posts.create(post_data)
                end
            end
        end
    end
end
