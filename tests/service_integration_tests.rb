require 'mysql2'
require 'date'
require 'yaml'

require_relative '../service'

RSpec.describe Service do
  before(:each) do
    database_config = Hash[YAML.load_file('../config/debug_config.yaml')['database'].map { |k, v| [k.to_sym, v] }]
    @client = Mysql2::Client.new(database_config)
    @client.query('DELETE FROM services;')
  end

  after(:each) do

  end

  it "saves information to the database" do
    service = Service.new(1, Time.new(2015, 04, 06, 17, 40), 2, 'Arran', 'Ardrossan - Brodick', 2)
    service.additional_info = '<p>A1 road closed</p>'
    service.disruption_reason = 'weather'
    service.disruption_date = Time.new(2015, 04, 03, 04, 20)
    service.disruption_details = '<p>weather is pretty bad</p>'
    service.save(@client)

    db_service = @client.query('SELECT * FROM services;').first

    expect(db_service['service_id']).to be == 1
    expect(db_service['updated']).to be == Time.new(2015, 04, 06, 17, 40)
    expect(db_service['sort_order']).to be == 2
    expect(db_service['area']).to be == 'Arran'
    expect(db_service['route']).to be == 'Ardrossan - Brodick'
    expect(db_service['status']).to be == 2
    expect(db_service['additional_info']).to be == '<p>A1 road closed</p>'
    expect(db_service['disruption_reason']).to be == 'weather'
    expect(db_service['disruption_date']).to be == Time.new(2015, 04, 03, 04, 20)
    expect(db_service['disruption_details']).to be == '<p>weather is pretty bad</p>'
  end

  it "updates a service in the database" do
      service = Service.new(1, Time.new(2015, 04, 06, 17, 40), 2, 'Arran', 'Ardrossan - Brodick', 2)
      service.additional_info = '<p>A1 road closed</p>'
      service.disruption_reason = 'weather'
      service.disruption_date = Time.new(2015, 04, 03, 04, 20)
      service.disruption_details = '<p>weather is pretty bad</p>'
      service.save(@client)

      service.updated = Time.new(2015, 02, 04, 22, 23)
      service.sort_order = 3
      service.area = 'Bute'
      service.route = 'Rothsey - Wymbess Bay'
      service.status = 3
      service.additional_info = '<p>A2 road closed</p>'
      service.disruption_reason = 'technical'
      service.disruption_date = Time.new(2015, 02, 06, 02, 45)
      service.disruption_details = '<p>ramp broken</p>'
      service.save(@client)

      count = @client.query('SELECT count(*) FROM services;').count.to_i
      db_service = @client.query('SELECT * FROM services;').first

      expect(count).to be == 1

      expect(db_service['service_id']).to be == 1
      expect(db_service['updated']).to be == Time.new(2015, 02, 04, 22, 23)
      expect(db_service['sort_order']).to be == 3
      expect(db_service['area']).to be == 'Bute'
      expect(db_service['route']).to be == 'Rothsey - Wymbess Bay'
      expect(db_service['status']).to be == 3
      expect(db_service['additional_info']).to be == '<p>A2 road closed</p>'
      expect(db_service['disruption_reason']).to be == 'technical'
      expect(db_service['disruption_date']).to be == Time.new(2015, 02, 06, 02, 45)
      expect(db_service['disruption_details']).to be == '<p>ramp broken</p>'
  end

  it "returns a service for id" do
      service1 = Service.new(3, Time.new(2015, 04, 06, 17, 40), 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
      service1.additional_info = '<p>A1 road closed</p>'
      service1.disruption_reason = 'weather'
      service1.disruption_date = Time.new(2015, 04, 03, 04, 20)
      service1.disruption_details = '<p>weather is pretty bad</p>'
      service1.save(@client)

      db_service_1 = Service.fetch(@client, 3)
      expect(db_service_1).to be_instance_of(Service)
      expect(db_service_1.service_id).to be == 3
      expect(db_service_1.updated).to be_instance_of(Time)
      expect(db_service_1.updated).to be == Time.new(2015, 04, 06, 17, 40)
      expect(db_service_1.sort_order).to be == 2
      expect(db_service_1.area).to be == 'Arran'
      expect(db_service_1.route).to be == 'Ardrossan - Brodick'
      expect(db_service_1.status).to be == Service::NORMAL_SERVICE
      expect(db_service_1.additional_info).to be == '<p>A1 road closed</p>'
      expect(db_service_1.disruption_reason).to be == 'weather'
      expect(db_service_1.disruption_date).to be == Time.new(2015, 04, 03, 04, 20)
      expect(db_service_1.disruption_details).to be == '<p>weather is pretty bad</p>'
  end

  it "returns all services from database" do
      service1 = Service.new(1, Time.new(2015, 04, 06, 17, 40), 2, 'Arran', 'Ardrossan - Brodick', 2)
      service1.additional_info = '<p>A1 road closed</p>'
      service1.disruption_reason = 'weather'
      service1.disruption_date = Time.new(2015, 04, 03, 04, 20)
      service1.disruption_details = '<p>weather is pretty bad</p>'
      service1.save(@client)

      service2 = Service.new(2, Time.new(2015, 04, 06, 17, 40), 2, 'Arran', 'Ardrossan - Brodick', 2)
      service2.additional_info = '<p>A1 road closed</p>'
      service2.disruption_reason = 'weather'
      service2.disruption_date = Time.new(2015, 04, 03, 04, 20)
      service2.disruption_details = '<p>weather is pretty bad</p>'
      service2.save(@client)

      services = Service.fetch_all(@client)
      db_service_1 = services[0]
      db_service_2 = services[1]

      expect(services.count).to be == 2
      expect(db_service_1).to be_instance_of(Service)
      expect(db_service_2).to be_instance_of(Service)
  end
end
