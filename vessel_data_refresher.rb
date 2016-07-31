require 'mysql2'
require 'net/http'
require 'json'
require 'yaml'

require_relative 'vessel'

VESSEL_NAME_LOOKUP = {
    '235000864' => 'Hebrides'
}

def fetch_vessels(url)
    uri = URI(url)
    response = Net::HTTP.get(uri)
    vessels_data = JSON.parse(response)

    vessels = vessels_data.map { |vessel_data|
        vessel_name = VESSEL_NAME_LOOKUP[vessel_data[0]]

        vessel = Vessel.new(mmsi: vessel_data[0], updated: vessel_data[6], name: vessel_name, latitude: vessel_data[1], longitude: vessel_data[2])
        vessel.speed = vessel_data[3]
        vessel.course = vessel_data[4]
        vessel.status = vessel_data[5]

        vessel
    }

    return vessels
end

if __FILE__ == $0
    yaml = YAML.load_file(ARGV[0])

    api_key = yaml['marinetraffic']['api_key']
    api_url = "http://services.marinetraffic.com/api/exportvessels/#{api_key}/timespan:10/protocol:json"

    database_config = Hash[yaml['database'].map { |k, v| [k.to_sym, v] }]
    client = Mysql2::Client.new(database_config)

    vessels = fetch_vessels(api_url)
    vessels.each { |vessel|
        vessel.save(client)
    }
end
