require "daimon/redirector/version"

# Usage: add code below in `config/application.rb`
#
# `config.middleware.insert_before Rack::Runtime, Daimon::Redirector::Redirector`

module Daimon
  module Redirector
    class Error < StandardError; end

    # Your code goes here...
    #
    class Redirector
      def initialize(application)
        @application = application
      end

      def call(environment)
        Responder.new(@application, environment).response
      end

      class Responder
        attr_reader :app, :env

        def initialize(application, environment)
          @app = application
          @env = environment
        end

        # lookup for redirect rule by request_path.
        # if rule found, redirect to destination.
        def response
          # FIXME: `RedirectRule` should be in this gem
          rule =
            RedirectRule.find_from_cache_by(request_path: request_path)

          if rule.present?
            destination = ERB::Util.html_escape(rule.destination)

            [301, { "Location" => destination }, [%Q(You are being redirected <a href="#{destination}">#{destination}</a>)]]
          else
            app.call(env)
          end
        end

        private

        # FIXME: missing gem dependency `SimpleIDN`
        def request_host
          SimpleIDN.to_unicode(env["HTTP_HOST"].split(":").first)
        end

        def request_path
          URI.decode_www_form_component(env["PATH_INFO"])
        end
      end
    end
  end
end
