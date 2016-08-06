require 'mysql2'
require 'date'
require 'yaml'

require_relative '../service_notifier'
require_relative '../service'

class MockPushServiceWithNoPush
end

class MockPushServiceRaisesException
    def push
        raise 'A test exception.'
    end
end

class MockPushService
    attr_accessor :data, :send_channels

    def push(data, channels)
        @data = data
        @send_channels = channels
    end
end

RSpec.describe ServiceNotifier do
    before(:each) do
        database_config = Hash[YAML.load_file('../config/debug_config.yaml')['database'].map { |k, v| [k.to_sym, v] }]
        @client = Mysql2::Client.new(database_config)
        @client.query('DELETE FROM services;')
    end

    after(:each) do

    end

    it "it throws an error if initialized with push service who does not define push" do
        push_service = MockPushServiceWithNoPush.new()

        expect{ServiceNotifier.new(@client, push_service)}.to raise_error(PushServiceInterfaceError)
    end

    it "doesn't send a notification if the service doesn't exist in the database" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)
        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service_notifier.notify_if_required(service)

        expect(push_service.data).to be_nil
    end

    it "send notification to correct channel" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service.save(@client)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::SAILINGS_DISRUPTED)
        service_notifier.notify_if_required(service)

        expect(push_service.send_channels).to be == ["S7"]
    end

    it "doesn't notify if the status hasn't changed" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service.save(@client)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service_notifier.notify_if_required(service)

        expect(push_service.data).to be_nil
        expect(push_service.send_channels).to be_nil
    end

    it "doesn't notify if new status is unknown" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service.save(@client)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::UNKNOWN)
        service_notifier.notify_if_required(service)

        expect(push_service.data).to be_nil
        expect(push_service.send_channels).to be_nil
    end

    it "doesn't notify if db status is unknown" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::UNKNOWN)
        service.save(@client)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service_notifier.notify_if_required(service)

        expect(push_service.data).to be_nil
        expect(push_service.send_channels).to be_nil
    end

    it "sends correct message if sailings change to normal service" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::SAILINGS_DISRUPTED)
        service.save(@client)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service_notifier.notify_if_required(service)

        expect(push_service.data[:alert]).to be == "Normal services have resumed for Ardrossan - Brodick"
        expect(push_service.data[:service_id]).to be == 7
        expect(push_service.data[:category]).to be == 'disruption'
        expect(push_service.send_channels).to be == ["S7"]
    end

    it "sends correct message if sailings change to disrupted" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::NORMAL_SERVICE)
        service.save(@client)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::SAILINGS_DISRUPTED)
        service_notifier.notify_if_required(service)

        expect(push_service.data[:alert]).to be == "There is a disruption to the service Ardrossan - Brodick"
        expect(push_service.data[:service_id]).to be == 7
        expect(push_service.data[:category]).to be == 'disruption'
        expect(push_service.send_channels).to be == ["S7"]
    end

    it "sends correct message if sailings change to cancelled" do
        push_service = MockPushService.new()
        service_notifier = ServiceNotifier.new(@client, push_service)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::SAILINGS_DISRUPTED)
        service.save(@client)

        service = Service.new(7, Time.now.utc, 2, 'Arran', 'Ardrossan - Brodick', Service::SAILINGS_CANCELLED)
        service_notifier.notify_if_required(service)

        expect(push_service.data[:alert]).to be == "Sailings have been cancelled for Ardrossan - Brodick"
        expect(push_service.data[:service_id]).to be == 7
        expect(push_service.data[:category]).to be == 'disruption'
        expect(push_service.send_channels).to be == ["S7"]
    end
end
