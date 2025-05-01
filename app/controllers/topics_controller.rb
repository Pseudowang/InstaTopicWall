class TopicsController < ApplicationController
  before_action :set_topic, only: [:show, :edit, :update, :destroy, :refresh]
  
  def index
    # 显示所有话题和新建表单
    @topics = Topic.all.order(created_at: :desc) # 按照创建时间降序排列
  end

  def show
    # 显示单个话题及其帖子
    @posts = @topic.posts.order(timestamp: :desc) # 按照时间戳降序排列
  end

  def new
    @topic = Topic.new
  end

  def create
    @topic = Topic.new(topic_params)
    
    if @topic.save
      # 创建成功后立即获取Instagram帖子
      @topic.refresh_posts
      redirect_to @topic, notice: '话题创建成功并获取了最新帖子！'
    else
      render :new
    end
  end

  def edit
    # 编辑话题表单
    # @topic 已经在 before_action 中设置
  end

  def update
    if @topic.update(topic_params)
      # 更新话题信息后，可以选择性地刷新帖子
      # 如果标签变更，应该刷新
      @topic.refresh_posts if @topic.saved_change_to_hashtag?
      redirect_to @topic, notice: '话题更新成功！'
    else
      render :edit
    end
  end

  def destroy
    @topic.destroy
    redirect_to topics_path, notice: '话题删除成功！'
  end

  def refresh
    @topic.refresh_posts
    respond_to do |format|
      format.html { redirect_to @topic, notice: '话题帖子刷新成功！' }
      format.turbo_stream # 使用 refresh.turbo_stream.erb 模板
      format.json { render json: { message: '话题帖子刷新成功！' } }
    end
  end

  private
  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name, :hashtag, :description)
  end
end
