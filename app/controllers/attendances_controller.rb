class AttendancesController < ApplicationController
  include AttendancesHelper
  before_action :set_user, only: [:edit_one_month, :update_one_month, :update_month_approval, :edit_overtime_notice,:edit_one_month_notice, :edit_month_approval_notice]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month
  before_action :restrict_admin, only: [:edit_one_month]


  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  
  # 残業申請お知らせモーダル	
  def edit_overtime_notice
    @users = User.joins(:attendances).group("users.id").where(attendances: {indicater_reply: "申請中"})
    @attendances = Attendance.where.not(overtime_finished_at: nil).order("worked_on ASC")
  end

# 残業申請お知らせモーダル更新
  def update_overtime_notice
    ActiveRecord::Base.transaction do 
      o1 = 0
      o2 = 0
      o3 = 0
      overtime_notice_params.each do |id, item|
        if item[:indicater_reply].present?
          if (item[:change] == "1") && (item[:indicater_reply] == "なし" || item[:indicater_reply] == "承認" || item[:indicater_reply] == "否認")
            attendance = Attendance.find(id)
            if item[:indicater_reply] == "なし" 
              o1+= 1
              item[:overtime_finished_at] = nil
              item[:tomorrow] = nil
              item[:overtime_work] = nil
              item[:indicater_check] = nil
            elsif item[:indicater_reply] == "承認"
              item[:indicater_check] = nil
              o2 += 1
              attendance.indicater_check_anser = "残業申請を承認しました"
            elsif item[:indicater_reply] == "否認"
              item[:overtime_finished_at] = nil
              item[:tomorrow] = nil
              item[:overtime_work] = nil
              item[:indicater_check] = nil
              item[:indicater_check] = nil
              o3 += 1
              attendance.indicater_check_anser = "残業申請を否認しました"
            end
            attendance.update_attributes!(item)
          end
        else 
          flash[:danger] = "指示者確認を更新、または変更にチェックを入れて下さい"
          redirect_to user_url(params[:user_id])
          return
        end
      end
      flash[:success] = "【残業申請】　#{o1}件なし,　#{o2}件承認,　#{o3}件否認しました"
      redirect_to user_url(params[:user_id])
      return
    end
  rescue ActiveRecord::RecordInvalid 
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to edit_overtime_notice_user_attendance_url(@user,item)
  end

  # 残業申請モーダル
  def edit_overtime_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @superior = User.where(superior: true).where.not( id: current_user.id )
  end
  
  def update_overtime_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    if @attendance.update_attributes(overtime_params)
      flash[:success] = "残業申請を受け付けました"
      redirect_to user_url(@user)
    else
      flash[:danger] = "残業申請に失敗しました: " + @attendance.errors.full_messages.join(", ")
      redirect_to user_url(@user)
    end  
  end

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
    @attendance = Attendance.find(params[:id])
    @superior = User.where(superior: true).where.not( id: current_user.id )
  end

  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  # 勤怠変更申請お知らせモーダル
  def edit_one_month_notice
    @users = User.joins(:attendances).group("users.id").where(attendances: {indicater_reply_edit: "申請中"})
    @attendances = Attendance.where.not(started_edit_at: nil, finished_edit_at: nil, note: nil, indicater_reply_edit: nil ).order("worked_on ASC")
  end
  
  
  def update_one_month_notice
    ActiveRecord::Base.transaction do 
      e1 = 0
      e2 = 0
      e3 = 0
      attendances_notice_params.each do |id, item|
      if item[:indicater_reply_edit].present?
        if (item[:change_edit] == "1") && (item[:indicater_reply_edit] == "なし" || item[:indicater_reply_edit] == "承認" || item[:indicater_reply_edit] == "否認")
        attendance = Attendance.find(id)
         @user = User.find(attendance.user_id)
        if item[:indicater_reply_edit] == "なし" 
            e1+= 1
            item[:started_edit_at] = nil
            item[:finished_edit_at] = nil
            item[:tomorrow] = nil
            item[:note] = nil
            item[:indicater_check_edit] = nil
        elsif item[:indicater_reply_edit] == "承認"
            if attendance.started_before_at.blank?
              item[:started_before_at] = attendance.started_at
            end 
            item[:started_at] = attendance.started_edit_at
            if  attendance.finished_before_at.blank?
              item[:finished_before_at] = attendance.finished_at
            end 
            item[:finished_at] = attendance.finished_edit_at
            item[:indicater_check_edit] = nil
            e2 += 1          
            attendance.indicater_check_anser = "勤怠変更申請を承認しました"
        elsif item[:indicater_reply_edit] == "否認"
            item[:started_edit_at] = nil
            item[:finished_edit_at] = nil
            item[:tomorrow] = nil
            item[:note] = nil
            item[:indicater_check_edit] = nil
            e3 += 1
            attendance.indicater_check_edit_anser = "勤怠変更申請を否認しました"   
        end          
          attendance.update!(item)
        end
      else
          flash[:danger] = "指示者確認を更新、または変更にチェックを入れて下さい"
          redirect_to user_url(params[:user_id])
          return
      end
      end
      flash[:success] = "【勤怠変更申請】 #{e1}件なし, #{e2}件承認, #{e3}件否認しました"
      redirect_to user_url(params[:user_id])
      return
    end
  rescue ActiveRecord::RecordInvalid 
      flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
       redirect_to edit_one_month_notice_user_attendance_url(@user,item)
  end
  
     # 1ヶ月勤怠承認
  def update_month_approval
      # 特定したユーザーの現在の月を取得
      @attendance = @user.attendances.find_by(worked_on: params[:user][:month_approval])
      # パラメーター更新
      # mon = Date.strptime(@attendance.month_approval, format: :short2)
    if month_approval_params[:indicater_check_month].present?
      @attendance.update(month_approval_params)
      flash[:success] = "勤怠承認申請を受け付けました"
    else  
      flash[:danger] = "上長を選択して下さい"
    end
    redirect_to user_url(@user)
  end
  
  def edit_month_approval_notice
    @users = User.joins(:attendances).group("users.id").where(attendances: {indicater_reply_month: "申請中"}).where.not(id: current_user.id)
    @attendances = Attendance.where.not(month_approval: nil, indicater_reply_month: nil).order("month_approval ASC")
  end 
  
  # 1ヶ月勤怠承認更新
  def update_month_approval_notice
      ActiveRecord::Base.transaction do 
        a1 = 0
        a2 = 0
        a3 = 0
        month_approval_notice_params.each do |id, item|
        if item[:indicater_reply_month].present?
          if (item[:change_month] == "1") && (item[:indicater_reply_month] == "なし" || item[:indicater_reply_month] == "承認" || item[:indicater_reply_month] == "否認")
          attendance = Attendance.find(id)
          @user = User.find(attendance.user_id)
            if item[:indicater_reply_month] == "なし" 
              a1+= 1
              item[:month_approval] = nil
              item[:indicater_check_month] = nil
  
            elsif item[:indicater_reply_month] == "承認"
              a2+= 1
          attendance.indicater_check_month_anser = "1ヶ月分の勤怠をを承認しました"
  
            elsif item[:indicater_reply_month] == "否認"
              a3+= 1
          attendance.indicater_check_month_anser = "1ヶ月分の勤怠を否認しました"
            end
            attendance.update!(item)
          else 
              flash[:danger] = "指示者確認を更新、または変更にチェックを入れて下さい"
              redirect_to user_url(params[:user_id])
              return
          end
        end
        end
        flash[:success] = "【1ヶ月の承認申請】 #{a1}件なし, #{a2}件承認, #{a3}件否認しました"
        redirect_to user_url(params[:user_id])
        return
      end
  rescue ActiveRecord::RecordInvalid 
        flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
        redirect_to edit_month_approval_notice_user_attendance_url(@user,item)
  end
  
  def log
    @user = User.find(params[:user_id])
    # もし受け取ったパラメーターにworked_on(1i)とworked_on(2i)があれば(1iは年、2iは月)
    if params["worked_on(1i)"].present? && params["worked_on(2i)"].present?
      # 受け取ったworked_onの年と月を年/月にして、変数 year_monthに代入
      year_month = "#{params["worked_on(1i)"]}/#{params["worked_on(2i)"]}"
      # もし変数year_monthがあればDateTimeを日付に変換
      @day = DateTime.parse(year_month) if year_month.present?
      # @attendancesに@user.attendancesからindicater_reply_editカラムが承認のものとworked_on:のカラムが@dayのものを全て取得
      @attendances = @user.attendances.where(indicater_reply_edit: "承認").where(worked_on: @day.all_month)
    else
      @attendances = @user.attendances.where(indicater_reply_edit: "承認").order("worked_on ASC")
    end
  end 
  


  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:worked_on, :started_at, :finished_at, :started_edit_at, :finished_edit_at, :tomorrow_edit, :note, :indicater_check_edit, :indicater_reply_edit])[:attendances]
    end
    
    # 勤怠編集お知らせモーダル
    def attendances_notice_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :started_before_at, :finished_before_at, :started_edit_at, :finished_edit_at, :note, :indicater_reply_edit, :change_edit])[:attendances]
    end 

    # beforeフィルター

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
     # 残業申請モーダルの情報
    def overtime_params
      # attendanceテーブルの（残業終了予定時間,翌日、残業内容、指示者確認（どの上長か）、指示者確認（申請かどうか））
      params.require(:attendance).permit(:overtime_finished_at, :tomorrow, :overtime_work,:indicater_check,:indicater_reply)
    end
    # 残業申請お知らせモーダルの情報
    def overtime_notice_params
      # attendanceテーブルの（指示者確認,変更）
      params.require(:user).permit(attendances: [:overtime_work, :indicater_reply, :change, :indicater_check, :overtime_finished_at, :indicater_check_anser])[:attendances]
    end 
    
    # 1ヶ月承認申請
    def month_approval_params 
      # attendanceテーブルの（承認月,指示者確認、どの上長か）
      params.require(:user).permit(:month_approval, :indicater_reply_month, :indicater_check_month)
    end
    
     # 1ヶ月承認申請お知らせモーダル
    def month_approval_notice_params
      # attendanceテーブルの（承認月,指示者確認、変更,どの上長か）
      params.require(:user).permit(attendances: [:month_approval, :indicater_reply_month, :change_month, :indicater_check_month])[:attendances]
    end
end

