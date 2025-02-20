# frozen_string_literal: true

require "test_helper"

require "stringio"

describe Committee::SchemaValidator::OpenAPI3::OperationWrapper do
  describe 'validate' do
    before do
      @path = '/validate'
      @method = 'post'
      @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
    end

    def operation_object
      open_api_3_schema.operation_object(@path, @method)
    end

    HEADER = { 'Content-Type' => 'application/json' }

    SCHEMA_PROPERTIES_PAIR = [
        ['string', 'str'],
        ['integer', 1],
        ['boolean', true],
        ['boolean', false],
        ['number', 0.1],
    ]

    it 'correct data' do
      operation_object.validate_request_params(SCHEMA_PROPERTIES_PAIR.to_h, HEADER, @validator_option)
      assert true
    end

    it 'correct object data' do
      operation_object.validate_request_params({
                                     "object_1" =>
                                         {
                                             "string_1" => nil,
                                             "integer_1" => nil,
                                             "boolean_1" => nil,
                                             "number_1" => nil
                                         }
                                 },
                                               HEADER,
                                               @validator_option)

      assert true
    end

    it 'invalid params' do
      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"string" => 1}, HEADER, @validator_option)
      }

      # FIXME: when ruby 2.3 dropped, fix because ruby 2.3 return Fixnum, ruby 2.4 or later return Integer
      assert e.message.start_with?("1 class is #{1.class} but it's not valid")
    end

    it 'support put method' do
      @method = "put"
      operation_object.validate_request_params({"string" => "str"}, HEADER, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"string" => 1}, HEADER, @validator_option)
      }

      # FIXME: when ruby 2.3 dropped, fix because ruby 2.3 return Fixnum, ruby 2.4 or later return Integer
      assert e.message.start_with?("1 class is #{1.class} but it's not valid")
    end

    it 'support patch method' do
      @method = "patch"
      operation_object.validate_request_params({"integer" => 1}, HEADER, @validator_option)

      e = assert_raises(Committee::InvalidRequest) {
        operation_object.validate_request_params({"integer" => "str"}, HEADER, @validator_option)
      }

      assert e.message.start_with?("str class is String but it's not valid")
    end

    it 'unknown param' do
      operation_object.validate_request_params({"unknown" => 1}, HEADER, @validator_option)
    end

    describe 'support get method' do
      before do
        @method = "get"
      end

      it 'correct' do
        operation_object.validate_request_params(
            {"query_string" => "query", "query_integer_list" => [1, 2]},
            HEADER,
            @validator_option
        )

        operation_object.validate_request_params(
            {"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => 1},
            HEADER,
            @validator_option
        )

        assert true
      end

      it 'not exist required' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"query_integer_list" => [1, 2]}, HEADER, @validator_option)
        }

        assert e.message.start_with?("required parameters query_string not exist in")
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params(
              {"query_string" => 1, "query_integer_list" => [1, 2], "optional_integer" => 1},
              HEADER,
              @validator_option
          )
        }

        # FIXME: when ruby 2.3 dropped, fix because ruby 2.3 return Fixnum, ruby 2.4 or later return Integer
        assert e.message.start_with?("1 class is #{1.class} but")
      end
    end

    describe 'support delete method' do
      before do
        @path = '/characters'
        @method = "delete"
      end

      it 'correct' do
        operation_object.validate_request_params({"limit" => "1"}, HEADER, @validator_option)

        assert true
      end

      it 'invalid type' do
        e = assert_raises(Committee::InvalidRequest) {
          operation_object.validate_request_params({"limit" => "a"}, HEADER, @validator_option)
        }

        assert e.message.start_with?("a class is String but")
      end
    end
  end
end
