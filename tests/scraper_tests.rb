# scraper.rb

require 'fakeweb'
require_relative '../scraper'

RSpec.describe Scraper do
    before(:each) do
        FakeWeb.allow_net_connect = false

        services_html_path = File.expand_path("../mock_data/services.html", __FILE__)
        services_stream = File.read(services_html_path)
        FakeWeb.register_uri(:get, "http://status.calmac.info", :body => services_stream, :content_type => "text/html")

        #affected
        coll_html_path = File.expand_path("../mock_data/coll.html", __FILE__)
        coll_stream = File.read(coll_html_path)
        FakeWeb.register_uri(:get, %r|http://status\.calmac\.info/\?route=16|, :body => coll_stream, :content_type => "text/html")

        #beware
        north_uist_html_path = File.expand_path("../mock_data/north_uist.html", __FILE__)
        north_uist_stream = File.read(north_uist_html_path)
        FakeWeb.register_uri(:get, %r|http://status\.calmac\.info/\?route=23|, :body => north_uist_stream, :content_type => "text/html")

        #normal with information
        lismore_html_path = File.expand_path("../mock_data/lismore.html", __FILE__)
        lismore_stream = File.read(lismore_html_path)
        FakeWeb.register_uri(:get, %r|http://status\.calmac\.info/\?route=(?!16)(?!23)(.)+|, :body => lismore_stream, :content_type => "text/html")
    end

    describe "#service" do
        it "has required fields" do 
            scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
            services = scraper.scrape()
            services.each { |s|
                expect(s.service_id).to be > 0
                expect(s.updated).to be_instance_of(Time)
                expect(s.sort_order).to be_truthy
                expect(s.area.length).to be > 0
                expect(s.route.length).to be > 0
                expect(s.status).to be_between(Service::NORMAL_SERVICE, Service::SAILINGS_CANCELLED).inclusive
            }
        end

        it "has correct disruption date" do
            scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
            services = scraper.scrape()

            north_uist_service = services.select { |service| service.service_id == 23 }.first

            expect(north_uist_service.disruption_date).to eq(Time.utc(2016,6,8,5,43,0))

        end
    end

    describe "#service_list" do
        it "returns all services in service.html" do
            scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
            services = scraper.scrape()
            expect(services.length).to be == 27
        end

        it "has Arran (Lochranza - Claonaig) at index 2" do 
            scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
            services = scraper.scrape()
            service = services[2]

            expect(service.service_id).to be == 6
            expect(service.updated).to be_instance_of(Time)
            expect(service.sort_order).to be == 2
            expect(service.area).to be == 'ARRAN'
            expect(service.route).to be == 'Claonaig - Lochranza '
            expect(service.status).to be == Service::NORMAL_SERVICE
        end
    end
end