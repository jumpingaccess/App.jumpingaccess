require "test_helper"

class Admin::MeetingsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get admin_meetings_show_url
    assert_response :success
  end
end
