class ApplicationPolicy
  # Extend this class to require user authentication
  def initialize(user, record)
    raise ErrorWithCode.new('must be logged in', 'UNAUTHORIZED') unless user

    @user = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      raise ErrorWithCode.new('must be logged in', 'UNAUTHORIZED') unless user

      @user = user
      @scope = scope
    end

    # graphql-pundit will scope any list or connection.
    # default: no filter
    def resolve
      @scope.all
    end
  end

  # Method used to trigger the policy
  def signed_in?
    !@user.nil?
  end
end
