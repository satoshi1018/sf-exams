class PostCategoriesController < ApplicationController
  def index
    @post_categories = PostCategory.find(params[:id])
  end
  
  def new
    @post_category = PostCategory.new
  end

  def create
    @post_category = PostCategory.new(post_category_params)
    if @post_category.save
      flash[:success] = "接続しました"
      redirect_to posts_path
    else
      flash.now[:danger] = "接続に失敗しました"
      render 'new'
    end
  end

  def destroy
    @post_category = PostCategory.find(params[:id])
    if @post_category.destroy
      flash[:success] = "接続を削除しました"
      redirect_to 'index'
    else
      flash[:warning] = "接続を削除できませんでした"
      redirect_to 'index'
    end
  end

  private

  def post_category_params
    params.require(:post_category).permit(:post_id, :category_id)
  end

end
