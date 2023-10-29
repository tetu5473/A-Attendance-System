module UsersHelper

  # 勤怠基本情報を指定のフォーマットで返します。  
  def format_basic_info(time)
    # format("%.2f", ((time.hour * 60) + time.min) / 60.0)
      time.strftime('%H:%M')
  end
end