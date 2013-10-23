module ProtocolGenerator

  BASIC_TYPES = ['int', 'nil', 'bool', 'float', 'bytes', 'string'].freeze
  MSGPACK2JAVA = {
      'int' => 'int',
      'nil' => 'null',
      'bool' => 'boolean',
      'float' => 'float',
      'bytes' => 'byte[]',
      'string' => 'String',
      'msgpack' => 'Value'
  }.freeze

  MSGPACK2RUBY = {
      'int' => 'Fixnum',
      'nil' => 'NilClass',
      'bool' => 'Boolean', # No bool in ruby... currently MSGPACK2RUBY is used only in docstrings so that's not a problem
      'float' => 'Float',
      'bytes' => 'bytes',
      'string' => 'String',
      'msgpack' => 'Object'

  }.freeze

  module Schema

    SERVER_CONF = {
      "type" => "object",
      'required' => true,
      "properties" => {
        "plugins" => {'type' => 'array', 'required' => true},
        "agent_name" => {'type' => 'string', 'required' => true},
        "message_size_limit" => {'type' => 'int', 'required' => false},
        "message_part_size" => {'type' => 'int', 'required' => false}
      }
    }.freeze

    DEVICE_CONF = {
      "type" => "object",
      'required' => true,
      "properties" => {
        "plugins" => {'type' => 'array', 'required' => true},
        "java_package" => {'type' => 'string', 'required' => true},
        "mdi_framework_jar" => {'type' => 'string', 'required' => false},
        "keep_java_source" => {'type' => 'bool', 'required' => false},
        "keep_java_jar" => {'type' => 'bool', 'required' => false},
        "agent_name" => {'type' => 'string', 'required' => true},
        "message_size_limit" => {'type' => 'int', 'required' => false},
        "message_part_size" => {'type' => 'int', 'required' => false}
      }
    }.freeze

    MSGPACK_CONF = {}.freeze

    PROTOBUF_CONF = {
      "type" => "object",
      'required' => true,
      "properties" => {
        "proto_file_name" => {'type' => 'string', 'required' => true},
        "protobuf_jar" => {'type' => 'string', 'required' => true},
        "package_name" => {'type' => 'string', 'required' => true}
      }
    }.freeze

    FIELD = {
      'type' => 'object',
      'properties' => {
        'type' => {'type'=>'string', 'required' => true},
        'modifier' => {'type'=>'string', 'enum' => ['required', 'optional'], 'required' => true},
        'array' => {'type'=>'bool', 'required' => false},
        'docstring' => {'type'=>'string', 'required' => false}
      }
    }.freeze

    MESSAGES = {
      'type' => 'object',
      'required' => true,
      'properties' => {},
      "patternProperties" => {
        "^[A-Z]" => {
          'type' => 'object',
          'properties' => {
            '_description' => {'type' => 'string', 'required' => false},
            '_way' => {'type' => 'string', 'enum' => ['toServer', 'toDevice', 'both', 'none'], 'required' => true},
            '_server_callback' => {'type' => 'string', 'required' => false},
            '_device_callback' => { 'type' => 'string', 'required' => false},
            '_timeout_calls' => {'type' => 'Array', 'required' => false}, # ["send", "ack"]
            '_timeouts' => {
              'type' => 'object',
              'required' => false,
              'properties' => {
                'send' => {'type' => 'int', 'required' => false},
              }
            }
          },
          "patternProperties" => {
            "^[a-z]" => FIELD
          }
        }
      }
    }.freeze

    COOKIES = {
      'type' => 'object',
      'required' => true,
      'properties' => {},
      "patternProperties" => {
        "^[A-Z]" => {
          'type' => 'object',
          'properties' => {
            "_send_with" => { 'type' => 'Array' },
            "_secure" => { 'type' => 'string', 'enum' => ['high', 'low', 'none']},
            "_validity_time" => {'type' => 'int', 'required' => false}
            },
          "patternProperties" => {
            "^[a-z]" => FIELD
          }
        }
      }
    }.freeze

    SHOTS = {
      "type" => "object",
      "required" => true,
      "patternProperties" => {
        "^[A-Z]" => {
          "type" => "object",
          "properties" => {
            "way" => {"type" => "string", "required" => true, "enum" => ['toDevice', 'toServer']},
            "message_type" => {"type" => "string", "required" => true},
            "next_shots" => {"type" => "Array", "items" => { "type" => "string"}}
          }
        }
      }
    }.freeze

    SEQUENCES = {
      "type" => "object",
      "required" => true,
      "patternProperties" => {
        "^[A-Z]" => {
          "type" => "object",
          "properties" => {
            "first_shot" => {"type" => "string", "required" => true},
            "shots" => SHOTS
          }
        }
      }
    }.freeze


    GENERAL = {
      "type" => "object",
      "properties" => {
        "name" => {"type" => "string", "required" => true, "pattern" => "^[A-Z]"},
        "messages" => MESSAGES,
        "cookies" => COOKIES,
        "sequences" => SEQUENCES,
        "protocol_version" => {"type" => "int", "required" => true},
        "protogen_version" => {"type" => "int", "required" => true, "enum" => [1]}
      }
    }.freeze

  end

end