class Topic < ApplicationRecord
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
    def process_posts(posts_data)
        posts_data.each do |post_data|
            if post_data[:instagram_id].present? # 修正方法名称
                post_data[:id_prefile] ||= "ig_#{post_data[:instagram_id]}"
                existing_post = posts.find_by(instagram_id: post_data[:instagram_id])
                if existing_post
                    existing_post.update(post_data)
                else
                    posts.create(post_data)
                end
            end
        end
    end
end
