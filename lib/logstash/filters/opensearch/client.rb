# encoding: utf-8
require "opensearch"
require "base64"

module LogStash
  module Filters
    class OpenSearchClient

      attr_reader :client

      def initialize(logger, hosts, options = {})
        ssl = options.fetch(:ssl, false)
        user = options.fetch(:user, nil)
        password = options.fetch(:password, nil)
        api_key = options.fetch(:api_key, nil)

        transport_options = {:headers => {}}
        transport_options[:headers].merge!(setup_basic_auth(user, password))
        transport_options[:headers].merge!(setup_api_key(api_key))

        hosts = hosts.map { |host| { host: host, scheme: 'https' } } if ssl
        # set ca_file even if ssl isn't on, since the host can be an https url
        ssl_options = { ssl: true, ca_file: options[:ca_file] } if options[:ca_file]
        ssl_options ||= {}

        logger.info("New OpenSearch filter client", :hosts => hosts)
        @client = ::OpenSearch::Client.new(hosts: hosts, transport_options: transport_options, :ssl => ssl_options)
      end

      def search(params)
        @client.search(params)
      end

      private

      def setup_basic_auth(user, password)
        return {} unless user && password && password.value
        
        token = ::Base64.strict_encode64("#{user}:#{password.value}")
        { Authorization: "Basic #{token}" }
      end

      def setup_api_key(api_key)
        return {} unless (api_key && api_key.value)

        token = ::Base64.strict_encode64(api_key.value)
        { Authorization: "ApiKey #{token}" }
      end
    end
  end
end
