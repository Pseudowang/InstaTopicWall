# InstaTopicWall

InstaTopicWall是一个Rails应用程序，允许用户创建主题并从Instagram获取相关帖子，用于展示和分享.


### 本地使用

1. 克隆仓库
```bash
git clone https://github.com/Pseudowang/InstaTopicWall.git
cd InstaTopicWall
```

2. 安装依赖
```bash
bundle install
rails tailwindcss:install
```

3. 设置数据库
```bash
rails db:create
rails db:migrate
```

4. 启动服务器

```bash

rails s -b 0.0.0.0 # 仅启动Rails服务器
```

5. 访问应用
打开浏览器访问 `http://localhost:3000`

#### 项目架构以及实现思路
![](https://wangzhrbuckets.s3.bitiful.net/picture/2025/05/ff6c964d47e4b04684532ce86d092e31.png)


![Timeline 1](https://www.bilibili.com/video/BV1xWGBzeEeP)

