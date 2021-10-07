class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :update_index, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:edit, :update, :update_index, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:show, :edit, :update,]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info, :all_user_edit]
  before_action :set_one_month, only: :show

  def index
    @users = User.where('name LIKE(?)', "%#{params[:name]}%").paginate(page: params[:page], per_page: 20)
  end
  
  # def self.search(search)
  #   if search
  #     User.where('title LIKE(?)', "%#{search}%")
  #   else
  #     User.all
  #   end
  # end
  
  # def search
  #   @users = User.search(params[:name])
  # end
  
   def import
    if params[:file].blank?
      flash[:danger]= "csvファイルを選択してください"
      redirect_to users_url
    elsif 
      File.extname(params[:file].original_filename) != ".csv"
      flash[:danger]= "csvファイル以外は出力できません"
      redirect_to users_url
    else
      User.import(params[:file]) 
      flash[:success]= "インポートが完了しました"
      redirect_to users_url
    end
   rescue ActiveRecord::RecordInvalid
      flash[:danger]= "不正なファイルのため、インポートに失敗しました"
      redirect_to users_url
   rescue ActiveRecord::RecordNotUnique
      flash[:danger]= "既にインポート済です"
      redirect_to users_url
   end
      
  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
    @overtime = Attendance.where(indicater_reply: "申請中", indicater_check: @user.name).count
    @change = Attendance.where(indicater_reply_edit: "申請中", indicater_check_edit: @user.name).count
    @month = Attendance.where(indicater_reply_month: "申請中", indicater_check_month: @user.name).count
    @superior = User.where(superior: true).where.not( id: current_user.id )
    @attendance = @user.attendances.find_by(worked_on: @first_day)
    # csv出力
    respond_to do |format|
      format.html
      filename = @user.name + "：" + l(@first_day, format: :middle) + "分" + " " + "勤怠"
      format.csv { send_data render_to_string, type: 'text/csv; charset=shift_jis', filename: "#{filename}.csv" }
    end
  end
  def update_index
    # debugger
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to users_url
    else
      flash[:danger] = "更新に失敗しました。"
      redirect_to users_url
    end 
  end 
  
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :edit      
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end
  
  def all_user_edit
  end

  def edit_basic_info
  end
  
  def working 
    # ユーザーモデルから全てのユーザーに紐づいた勤怠たちを代入
    @users = User.all.includes(:attendances)
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end

  private
  # "ここに書いてあるのがストロングパラメーターという"

    def user_params
      params.require(:user).permit(:name, :email, :affiliation,:employee_number,:uid, :password, 
        :password_confirmation, :basic_work_time, :designated_work_start_time, :designated_work_end_time)
    end

    def basic_info_params
      params.require(:user).permit(:department, :basic_time, :work_time)
    end
end

