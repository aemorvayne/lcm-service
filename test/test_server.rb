# frozen_string_literal: true

require 'minitest/autorun'
require 'net/http'
require 'rbconfig'
require 'socket'

require_relative '../server'

class LcmServiceTest < Minitest::Test
  def test_email_path
    assert_equal 'your_name_example_com', LcmService.email_path('your.name@example.com')
  end

  def test_email_path_preserves_letters_and_digits_and_replaces_punctuation
    assert_equal 'User_Name_tag_42_example_domain_example_com',
                 LcmService.email_path('User.Name+tag_42@example-domain.example.com')
    assert_equal '_ser_example_com', LcmService.email_path('üser@example.com')
  end

  def test_valid_numbers
    {
      'x=6&y=8' => '24',
      'x=21&y=6' => '42',
      'x=1&y=42' => '42',
      'x=12&y=12' => '12',
      'x=0&y=42' => '0',
      'x=42&y=0' => '0',
      'x=0&y=0' => '0',
      'x=0003&y=0009' => '9',
      'x=3&y=5' => '15',
      'x=2&y=100000000000000000000000000000000' => '100000000000000000000000000000000',
      'x=100000000000000000003&y=3' => '300000000000000000009',
      'y=18&x=12' => '36',
      'x=%31%32&y=18' => '36'
    }.each do |query, expected|
      assert_equal expected, LcmService.calculate(query), "query=#{query}"
    end
  end

  def test_invalid_or_missing_numbers
    [
      nil, '', 'x=3', 'y=3', 'x=3&y', 'x=&y=3', 'x=3&y=',
      'x=-1&y=5', 'x=5&y=-1', 'x=1.5&y=2', 'x=1e3&y=2',
      'x=abc&y=3', 'x=%2B3&y=2', 'x=+3&y=2', 'x=3%20&y=2',
      'x=%EF%BC%93&y=2', 'x=3%0A&y=2', 'x=%GG&y=3',
      'x=2&x=3&y=6', 'x=2&y=3&y=4', 'x=2&%78=3&y=6',
      'x=0&y=invalid', 'x=invalid&y=0'
    ].each do |query|
      assert_equal 'NaN', LcmService.calculate(query), "query=#{query.inspect}"
    end
  end
end

class HttpTest < Minitest::Test
  EMAIL = 'service.user+test@example.org'
  ENDPOINT = '/service_user_test_example_org'

  def test_get_returns_exact_plain_text
    with_server do |http|
      response = http.get("#{ENDPOINT}?x=12&y=18")

      assert_plain_text response, '36'
    end
  end

  def test_zero_large_and_encoded_numbers
    with_server do |http|
      {
        'x=0&y=42' => '0',
        'x=42&y=0' => '0',
        'x=0&y=0' => '0',
        'x=0003&y=0009' => '9',
        'x=100000000000000000003&y=3' => '300000000000000000009',
        'y=18&x=%31%32' => '36'
      }.each do |query, expected|
        assert_plain_text http.get("#{ENDPOINT}?#{query}"), expected
      end
    end
  end

  def test_invalid_input_returns_nan
    with_server do |http|
      [
        'x=-1&y=5', 'x=1.5&y=2', 'x=%2B3&y=2', 'x=3%20&y=2',
        'x=3%0A&y=2', 'x=%EF%BC%93&y=2', 'x=0&y=invalid',
        'x=2&x=3&y=6', 'x=2&y=3&y=4', 'x=2&%78=3&y=6',
        'x=3', 'y=3', 'x=3&y', 'x=&y=3', ''
      ].each do |query|
        assert_plain_text http.get("#{ENDPOINT}?#{query}"), 'NaN'
      end
    end
  end

  def test_missing_query_returns_nan
    with_server do |http|
      assert_plain_text http.get(ENDPOINT), 'NaN'
    end
  end

  def test_other_paths_return_404
    with_server do |http|
      ['/', '/wrong_path', '/your_name_example_com', "#{ENDPOINT}/extra"].each do |path|
        assert_plain_text http.get("#{path}?x=12&y=18"), 'Not Found', status: '404'
      end
    end
  end

  def test_default_email_when_environment_variable_is_unset
    with_server(email: nil) do |http|
      assert_plain_text http.get('/your_name_example_com?x=12&y=18'), '36'
      assert_plain_text http.get("#{ENDPOINT}?x=12&y=18"), 'Not Found', status: '404'
    end
  end

  def test_non_get_methods_are_not_allowed
    with_server do |http|
      %w[POST PUT PATCH DELETE OPTIONS].each do |method|
        response = http.send_request(method, "#{ENDPOINT}?x=12&y=18")

        assert_plain_text response, 'Method Not Allowed', status: '405'
        assert_equal 'GET', response['Allow'], "method=#{method}"
      end
    end
  end

  def test_head_is_not_allowed_and_has_no_body
    with_server do |http|
      response = http.head("#{ENDPOINT}?x=12&y=18")

      assert_plain_text response, nil, status: '405'
      assert_equal 'GET', response['Allow']
    end
  end

  private

  def assert_plain_text(response, body, status: '200')
    assert_equal status, response.code
    assert_equal 'text/plain; charset=utf-8', response['Content-Type']
    assert_equal 'no-store', response['Cache-Control']
    if body.nil?
      assert_nil response.body
    else
      assert_equal body, response.body
    end
  end

  def with_server(email: EMAIL)
    listener = TCPServer.new('127.0.0.1', 0)
    port = listener.addr[1]
    listener.close

    pid = Process.spawn(
      { 'EMAIL_ADDRESS' => email, 'PORT' => port.to_s },
      RbConfig.ruby, File.expand_path('../server.rb', __dir__),
      out: File::NULL, err: File::NULL
    )

    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    loop do
      begin
        socket = TCPSocket.new('127.0.0.1', port)
        socket.close
        break
      rescue Errno::ECONNREFUSED
        raise 'server did not start' if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.025
      end
    end

    Net::HTTP.start('127.0.0.1', port, nil, nil, open_timeout: 2, read_timeout: 2) do |http|
      yield http
    end
  ensure
    if pid
      begin
        Process.kill('TERM', pid)
      rescue Errno::ESRCH
        nil
      end
      Process.wait(pid)
    end
  end
end
