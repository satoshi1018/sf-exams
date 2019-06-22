class PostCategoriesController < ApplicationController
  def new
    @post_category = PostCategory.new
  end

  def create
    @postcategory = Post_category.new(post_category_params)
    @post_category.save!
    render 'new'
  end

  def destroy
    @postcategory = Post_category.find(params[:id])
    @post_category.destroy
    render "new"
  end

end
