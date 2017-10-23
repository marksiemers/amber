require "json"

module Amber::Router
  alias ParamsType = String | JSON::Type
  alias ParamsHash = Hash(String | Symbol, Amber::Router::ParamsType)

  # The Parameters module will parse parameters from a URL, a form post or a JSON
  # post and provide them in the self params hash.  This unifies access to
  # parameters into one place to simplify access to them.
  # Note: other params from the router will be handled in the router handler
  # instead of here.  This removes a dependency on the router in case it is
  # replaced or not needed.
  module ParamsParser
    URL_ENCODED_FORM = "application/x-www-form-urlencoded"
    MULTIPART_FORM   = "multipart/form-data"
    APPLICATION_JSON = "application/json"
    METHOD           = "_method"
    OVERRIDE_HEADER  = "X-HTTP-Method-Override"
    OVERRIDE_METHODS = %w(PATCH PUT DELETE)

    property params = Hash(String | Symbol, ParamsType).new

    @override_method : String?

    def clear_params
      @params = Hash(String | Symbol, ParamsType).new
    end

    def parse_params
      parse_part(request.query)
      if content_type = request.headers["Content-Type"]?
        parse_multipart if content_type.try(&.starts_with?(MULTIPART_FORM))
        parse_part(request.body) if content_type.try(&.starts_with?(URL_ENCODED_FORM))
        parse_json if content_type.includes? APPLICATION_JSON
      end
    end

    # Adds Request Method Override support to the framework.
    # Param supported
    # - *_method* can be passed as a form or url param
    #
    # HTTP Headers supported:
    # - *X-HTTP-Method-Override* (Google/GData)
    #
    # The convention has been established that the GET and HEAD methods SHOULD NOT
    # have the significance of taking an action other than retrieval.
    #
    # These methods ought to be considered "safe". This allows user agents to
    # represent other methods, such as POST, PUT and DELETE, in a special way,
    # so that the user is made aware of the fact that a possibly unsafe action
    # is being requested.
    #
    # Read RFC 2616 - HTTP 1.1 section 9.1.1
    # (https://tools.ietf.org/html/rfc2616#section-9.1)
    #
    # In other words, if you are tempted to use a GET to simulate a PUT or DELETE,
    # don't do it. Use a POST instead.
    def override_request_method!
      # If the current request method is not GET or POST it means that it was
      # already overridden
      return unless %(GET POST).includes? request.method
      if (method = override_method) && override_method?
        request.method = method
      end
    end

    # Determines the existence of HTTP Request Method Override in headers
    def override_header?
      request.headers[OVERRIDE_HEADER]?
    end

    private def override_method?
      OVERRIDE_METHODS.includes? override_method
    end

    private def override_method
      @override_method ||= (params[METHOD]? || override_header?).try &.to_s.upcase
    end

    def merge_route_params
      route_params.each { |k, v| params[k] = v }
    end

    def route_params
      route.params
    end

    def parse_json
      if body = request.body.not_nil!.gets_to_end
        if body.size > 2
          case json = JSON.parse(body).raw
          when Hash
            json.each do |key, value|
              params[key.as(String)] = value
            end
          when Array
            params["_json"] = json
          end
        end
      end
    end

    def parse_multipart
      HTTP::FormData.parse(request) do |upload|
        next unless upload
        filename = upload.filename
        if filename.is_a?(String) && !filename.empty?
          files[upload.name] = Files::File.new(upload: upload)
        else
          params[upload.name] = upload.body.gets_to_end
        end
      end
    end

    private def parse_part(part)
      values = case part
               when IO
                 part.gets_to_end
               when String
                 part.to_s
               else
                 ""
               end

      HTTP::Params.parse(values) do |key, value|
        params[key] = value
      end
    end
  end
end
