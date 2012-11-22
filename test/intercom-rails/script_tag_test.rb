require 'active_support/core_ext/string/output_safety'
require 'test_setup'

class ScriptTagTest < MiniTest::Unit::TestCase

  include IntercomRails

  def test_output_is_html_safe?
    assert_equal true, ScriptTag.generate({}).html_safe?
  end

  def test_converts_times_to_unix_timestamps
    time = Time.new(1993,02,13)
    top_level_time = ScriptTag.new(:user_details => {:created_at => time})
    assert_equal time.to_i, top_level_time.intercom_settings[:created_at]

    now = Time.now
    nested_time = ScriptTag.new(:user_details => {:custom_data => {"something" => now}})
    assert_equal now.to_i, nested_time.intercom_settings[:custom_data]["something"]
  end

  def test_strips_out_nil_entries_for_standard_attributes
    %w(name email user_id).each do |standard_attribute|
      with_value = ScriptTag.new(:user_details => {standard_attribute => 'value'})
      assert_equal with_value.intercom_settings[standard_attribute], 'value'

      with_nil_value = ScriptTag.new(:user_details => {standard_attribute.to_sym => 'value'})
      assert with_nil_value.intercom_settings.has_key?(standard_attribute.to_sym), "should strip :#{standard_attribute} when nil"

      with_nil_value = ScriptTag.new(:user_details => {standard_attribute => 'value'})
      assert with_nil_value.intercom_settings.has_key?(standard_attribute), "should strip #{standard_attribute} when nil"
    end
  end

  def test_secure_mode_with_email
    script_tag = ScriptTag.new(:user_details => {:email => 'ciaran@intercom.io'}, :secret => 'abcdefgh')
    assert_equal Digest::SHA1.hexdigest('abcdefgh' + 'ciaran@intercom.io'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_with_user_id
    script_tag = ScriptTag.new(:user_details => {:user_id => '1234'}, :secret => 'abcdefgh')
    assert_equal Digest::SHA1.hexdigest('abcdefgh' + '1234'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_with_email_and_user_id
    script_tag = ScriptTag.new(:user_details => {:user_id => '1234', :email => 'ciaran@intercom.io'}, :secret => 'abcdefgh')
    assert_equal Digest::SHA1.hexdigest('abcdefgh' + '1234'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_with_secret_from_config
    IntercomRails.config.api_secret = 'abcd'
    script_tag = ScriptTag.new(:user_details => {:email => 'ben@intercom.io'})
    assert_equal Digest::SHA1.hexdigest('abcd' + 'ben@intercom.io'), script_tag.intercom_settings[:user_hash]
  end

  def test_secure_mode_chooses_passed_secret_over_config
    IntercomRails.config.api_secret = 'abcd'
    script_tag = ScriptTag.new(:user_details => {:email => 'ben@intercom.io'}, :secret => '1234')
    assert_equal Digest::SHA1.hexdigest('1234' + 'ben@intercom.io'), script_tag.intercom_settings[:user_hash]
  end

end
