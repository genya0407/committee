# frozen_string_literal: true

module Committee
  module Middleware
    class ResponseValidation < Base
      attr_reader :validate_success_only

      def initialize(app, options = {})
        super
        @validate_success_only = @schema.validator_option.validate_success_only
      end

      def handle(request)
        status, headers, response = @app.call(request.env)

        v = build_schema_validator(request)
        v.response_validate(status, headers, response) if v.link_exist? && self.class.validate?(status, validate_success_only)

        [status, headers, response]
      rescue Committee::InvalidResponse
        handle_exception($!, request.env)

        raise if @raise
        @error_class.new(500, :invalid_response, $!.message).render
      rescue JSON::ParserError
        handle_exception($!, request.env)

        raise Committee::InvalidResponse if @raise
        @error_class.new(500, :invalid_response, "Response wasn't valid JSON.").render
      end

      class << self
        def validate?(status, validate_success_only)
          status != 204 && (!validate_success_only || (200...300).include?(status))
        end
      end

      private

      def handle_exception(e, env)
        return unless @error_handler

        if @error_handler.arity > 1
          @error_handler.call(e, env)
        else
          warn <<-MESSAGE
          [DEPRECATION] Using `error_handler.call(exception)` is deprecated and will be change to
            `error_handler.call(exception, request.env)` in next major version.
          MESSAGE

          @error_handler.call(e)
        end
      end
    end
  end
end
