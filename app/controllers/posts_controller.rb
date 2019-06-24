class PostsController < ApplicationController
  before_action :correct_user?, only:[:edit, :update, :destroy]

  def index
    @posts = current_user.posts
  end

  def show
    @post = Post.find(params[:id])
    @comments = @post.comments
    @post_category = PostCategory.find(params[:id])
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)
    if @post.save
      flash[:success] = "投稿が完了しました"
      redirect_to @post
    else
      flash.now[:danger] = "投稿に失敗しました"
      render 'new'
    end
  end

  def update
    @post = Post.find(params[:id])
    if @post.update_attributes(post_params)
      flash[:success] = "投稿の編集が完了しました"
      redirect_to @post
    else
      flash.now[:warning] = "投稿の編集に失敗しました"
      render 'edit'
    end
  end

  def edit
    @post = Post.find(params[:id])
  end

  def destroy
    @post = Post.find(params[:id])
    if @post.destroy
      flash[:success] = "投稿を削除しました"
      redirect_to 'index'
    else
      flash[:warning] = "投稿を削除できませんでした"
      redirect_to 'index'
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :content)
  end

  def correct_user? # 実装してください
    unless current_user?
      flash[:warning] = "ユーザーが正しくありません"
      redirect_to root_url 
    end
  end
end