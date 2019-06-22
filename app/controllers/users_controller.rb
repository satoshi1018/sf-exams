class UsersController < ApplicationController
  before_action :login_user?, only: [:edit, :update, :destroy]
  before_action :admin_user?, only: [:destroy]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = "ユーザー登録が完了しました"
      redirect_to root_path
    else
      flash.now[:danger] = "ユーザーの作成に失敗しました"
      render 'new'
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "情報の更新が完了しました"
      redirect_to @user
    else
      flash.now[:warning] = "情報の更新に失敗しました"
      render 'edit'
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    flash[:success] = "ユーザーの削除が完了しました"
    redirect_to 'index'
  end

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @posts = @user.posts.order("created_at DESC").paginate(:page => params[:page], :per_page => 5)
    @comments = @user.comments.order("created_at DESC").paginate(:page => params[:page], :per_page => 5)
  end

  def edit
    @user = User.find(params[:id])
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def login_user?
    unless logged_in?
      flash[:warning] = "ログインしてください"
      redirect_to root_path
    end
  end

  def admin_user?
    flash[:warning] = "管理者権限がありません"
    redirect_to root_url and return
  end

end
