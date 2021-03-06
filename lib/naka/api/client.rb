require 'rest-client'
require 'multi_json'

module Naka
  module Api
    class Client
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def referer
        @referer ||= "http://#{user.api_host}/kcs/mainD2.swf?api_token=#{user.api_token}&api_starttime=#{user.api_at}"
      end

      def api_host
        @api_host ||= "http://#{user.api_host}"
      end

      def post(path, args = {})
        args.merge!(api_token: user.api_token, api_verno: 1)
        options = {
          referer: referer,
          host: user.api_host,
          origin: "http://#{user.api_host}",
          accept_encoding: 'gzip, deflate, sdch'
        }
        begin
          response = RestClient.post(File.join(api_host, path), args, options).
            force_encoding(Encoding::UTF_8).
            gsub("\xEF\xBB\xBF".force_encoding(Encoding::UTF_8), "").
            gsub(/^svdata=/, '')
          json = MultiJson.load response, :symbolize_keys => true
          raise unless json[:api_result] == 1
          json
        rescue => e
          p path, args
          puts response
          raise e
        end
      end
    end
  end
end
