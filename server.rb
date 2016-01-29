require 'sinatra'
require 'json'
require 'yaml'
require 'mysql2'

require_relative 'service'
require_relative 'vessel'

get '/services/' do
	content_type :json

	db_services = Service.fetch_all(db_client)

	db_services.map { |service|
		{
			'service_id' => service.service_id,
			'updated' => service.updated,
			'sort_order' => service.sort_order,
			'area' => service.area,
			'route' => service.route,
			'status' => service.status
		}
	}.to_json
end

get '/services/:id' do
	content_type :json

	db_service = Service.fetch(db_client, params['id'])

	return 'Service does not exist' if !db_service

	{
		'service_id' => db_service.service_id,
		'updated' => db_service.updated,
		'sort_order' => db_service.sort_order,
		'area' => db_service.area,
		'route' => db_service.route,
		'status' => db_service.status,
		'additional_info' => db_service.additional_info,
		'disruption_reason' => db_service.disruption_reason,
		'disruption_date' => db_service.disruption_date,
		'disruption_details' => db_service.disruption_details
	}.to_json
end

get '/vessels/' do
	content_type :json

	db_services = Vessel.fetch_all(db_client)

	db_services.map { |vessel|
		{
			'mmsi' => vessel.mmsi,
			'name' => vessel.name,
			'updated' => vessel.updated,
			'latitude' => vessel.latitude,
			'longitude' => vessel.longitude,
			'speed' => vessel.speed,
			'course' => vessel.course,
			'status' => vessel.status
		}
	}.to_json
end

def db_client
	yaml = YAML.load_file(ARGV[0])
	config = Hash[yaml['database'].map { |k, v| [k.to_sym, v] }]
	Mysql2::Client.new(config)
end
