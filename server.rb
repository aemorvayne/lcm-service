# frozen_string_literal: true

require 'uri'
require 'webrick'

module LcmService
  module_function

  def email_path(email)
    email.gsub(/[^A-Za-z0-9]/, '_')
  end

  def parse_number(value)
    return nil unless value.is_a?(String) && /\A[0-9]+\z/.match?(value)

    Integer(value, 10)
  end

  def calculate(query_string)
    params = URI.decode_www_form(query_string.to_s)
    xs = params.filter_map { |name, value| value if name == 'x' }
    ys = params.filter_map { |name, value| value if name == 'y' }
    return 'NaN' unless xs.length == 1 && ys.length == 1

    x = parse_number(xs.first)
    y = parse_number(ys.first)
    return 'NaN' if x.nil? || y.nil?
    return '0' if x.zero? || y.zero?

    ((x / x.gcd(y)) * y).to_s
  rescue ArgumentError, URI::InvalidURIError
    'NaN'
  end

  class Endpoint < WEBrick::HTTPServlet::AbstractServlet
    def initialize(server, path)
      super(server)
      @path = path
    end

    def service(request, response)
      response['Content-Type'] = 'text/plain; charset=utf-8'
      response['Cache-Control'] = 'no-store'

      if request.path != @path
        response.status = 404
        response.body = 'Not Found'
      elsif request.request_method != 'GET'
        response.status = 405
        response['Allow'] = 'GET'
        response.body = 'Method Not Allowed'
      else
        response.status = 200
        response.body = LcmService.calculate(request.query_string)
      end
    end
  end

  def start!
    email = ENV.fetch('EMAIL_ADDRESS', 'your.name@example.com')
    path = "/#{email_path(email)}"
    port = Integer(ENV.fetch('PORT', '8080'))

    server = WEBrick::HTTPServer.new(
      Port: port,
      BindAddress: '0.0.0.0',
      Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
      AccessLog: []
    )

    server.mount('/', Endpoint, path)

    %w[INT TERM].each { |signal| trap(signal) { server.shutdown } }
    server.start
  end
end

LcmService.start! if $PROGRAM_NAME == __FILE__
