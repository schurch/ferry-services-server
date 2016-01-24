# scraper.rb

require 'fakeweb'
require_relative '../scraper'

RSpec.describe Scraper do
	before(:each) do
		FakeWeb.allow_net_connect = false

		services_html_path = File.expand_path("../services.html", __FILE__)
		services_stream = File.read(services_html_path)
		FakeWeb.register_uri(:get, "http://status.calmac.info", :body => services_stream, :content_type => "text/html")

		arran_html_path = File.expand_path("../arran.html", __FILE__)
		arran_stream = File.read(arran_html_path)
		FakeWeb.register_uri(:get, %r|http://status\.calmac\.info/\?route=(?!07)(.)+|, :body => arran_stream, :content_type => "text/html")

		cumbrae_html_path = File.expand_path("../cumbrae.html", __FILE__)
		cumbrae_stream = File.read(cumbrae_html_path)
		FakeWeb.register_uri(:get, %r|http://status\.calmac\.info/\?route=07|, :body => cumbrae_stream, :content_type => "text/html")
	end

	describe "#service" do
		it "returns service type" do
			scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
			services = scraper.scrape()
			expect(services.first).to be_instance_of(Service)
		end

		it "has required fields" do 
			scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
			services = scraper.scrape()
			services.each { |s|
				expect(s.service_id).to be > 0
				expect(s.updated).to be_instance_of(Time)
				expect(s.sort_order).to be_truthy
				expect(s.area.length).to be > 0
				expect(s.route.length).to be > 0
        		expect(s.status).to be_between(Service::NORMAL_SERVICE, Service::SAILINGS_DISRUPTED).inclusive
			}
		end

		it "has a readable description" do 
			scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
			services = scraper.scrape()
			arran_service = services[2]
			expect(arran_service.to_s).to include('ARRAN')
		end
	end

	describe "#service_list" do
		it "returns all services in service.html" do
			scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
			services = scraper.scrape()
			expect(services.length).to be == 25
		end

		it "has Arran (Lochranza - Claonaig) at index 2" do 
			scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
			services = scraper.scrape()
			arran_service = services[2]

			expect(arran_service.service_id).to be == 6
			expect(arran_service.updated).to be_instance_of(Time)
			expect(arran_service.sort_order).to be == 2
			expect(arran_service.area).to be == 'ARRAN'
			expect(arran_service.route).to be == 'Claonaig - Lochranza (NB: summer only)'
			expect(arran_service.status).to be == Service::NORMAL_SERVICE
		end

		it "has Arran (Lochranza - Claonaig) with additional info" do
			scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
			services = scraper.scrape()
			arran_service = services[2]
			
			expect(arran_service.additional_info).to include('<p>Argyll &amp; Bute Council, Roads &amp; Amenity Services have introduced a temporary 18T MGW weight restriction on the B8001 Redhouse - Skipness Road, to safeguard the road and road users. The weight restriction is required due to land slippage which has caused structural damage to the road. This temporary weight restriction has been put in place under emergency powers until the 24 April 2015. This allows time to introduce a temporary traffic order which is expected to be in place till the 23 October 2015 or until such time repairs are complete.<br></p>')
		end

		it "has Cumbrae at index 10 with sailings disrupted" do
			scraper = Scraper.new(Scraper::CALMAC_ENDPOINT)
			services = scraper.scrape()
			cumbrae_service = services[10]

			expect(cumbrae_service.status).to be == Service::SAILINGS_DISRUPTED
			expect(cumbrae_service.disruption_reason).to be == 'Technical Reasons'
			expect(cumbrae_service.disruption_date).to be == Time.zone.local(2015, 04, 05, 22, 00).utc
			expect(cumbrae_service.disruption_details).to include('<p><span style="font-weight: bold; text-decoration: underline;">Monday 6th April&#160;</span></p><p>Due to technical issue there will be a smaller vessel operating with reduced vehicle carrying capacity, so lengthy delays are to be expected.</p><p>We apologise for the disruption this causes for our customers and thank you for your patience.</p>')
		end
	end
end