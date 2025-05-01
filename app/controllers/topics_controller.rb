class TopicsController < ApplicationController
  before_action :set_topic, only[:show, :edit, :update, :destroy, :refresh]
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
      redirect_to @topic, notice: '话题创建成功！'
    else
      render :new
    end
  end

  def edit
    # 编辑话题
    @topic = Topic.find(params[:id])
    
  end

  def update
    if @topic.update(topic_params)
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
    repond_to do |format|
      format.html { redirect_to @topic, notice: '话题帖子刷新成功！' }
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
