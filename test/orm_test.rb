require 'helper'

class OrmTest < Test::Unit::TestCase

  class User
    include CouchPotato::Persistence
    include Devise::Orm::CouchPotato

    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable
  end

  should "provide hash-like access to properties" do
    user = User.new
    user[:email] = 'foo@bar.com'
    assert_equal 'foo@bar.com', user[:email]
  end

end
