class SierraUser
  attr_accessor :login

  include SierraPostgresUtilities::Views::User

  def initialize(login)
    @login = login
  end

  def id
    iii_user.id
  end

  def permissions
    iii_user_permission_myuser.map { |r| [r.permission_num, r.permission_name] }
  end

  def statistic_group_code_num
    iii_user.statistic_group_code_num
  end
end
