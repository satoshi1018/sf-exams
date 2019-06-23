class CategoriesController < ApplicationController
	def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:success] = "カテゴリを作成しました"
      redirect_to categories_path
    else
      flash.now[:danger] = "カテゴリの作成に失敗しました"
      render 'new'
    end
  end

  def update
    @category = Category.find(params[:id])
    if @category.update_attributes(category_params)
      flash[:success] = "カテゴリの更新が完了しました"
      redirect_to @category
    else
      flash.now[:warning] = "カテゴリの更新に失敗しました"
      render 'edit'
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy
    flash[:success] = "カテゴリの削除が完了しました"
    redirect_to 'index'
  end

  def index
    @categories = Category.all
  end


  def edit
	end

	def show
		@category = Category.find(params[:id])
  end
	
	private

	def category_params
    params.require(:category).permit(:name)
  end

end
