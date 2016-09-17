require 'net/http'
require 'uri'
require 'json'

class ParsePushService
    def initialize(endpoint, application_id, master_key)
        @uri = URI.parse(endpoint)
        @http = Net::HTTP.new(@uri.host, @uri.port)
        @http.use_ssl = false
        @application_id = application_id
        @master_key = master_key
    end

    def push(data, parse_channels = nil)
        header = {
            'X-Parse-Application-Id' => @application_id,
            'X-Parse-Master-Key' => @master_key,
            'Content-Type' => 'application/json'
        }

        push_body = {
            'where' => {
                'deviceType' => 'ios'
            },
            'data' => data
        }

        push_body['where']['channels'] = { '$in' => parse_channels } if parse_channels
        request = Net::HTTP::Post.new(@uri.request_uri, header)
        request.body = push_body.to_json

        # Send the request
        @http.request(request)
    end
end
