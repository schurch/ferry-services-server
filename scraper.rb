require 'mechanize'
require 'mysql2'
require 'active_support/core_ext/time'

require_relative 'service'
require_relative 'parse_push_service'
require_relative 'service_notifier'

class Scraper
	CALMAC_ENDPOINT = 'http://status.calmac.info'

	attr_accessor :endpoint, :service_scrape_delay, :log

	def initialize(endpoint = CALMAC_ENDPOINT)
		@endpoint = endpoint
		@service_scrape_delay = 0
		@log = false

		Time.zone = 'London'
	end

	def scrape
		services = []

		agent = Mechanize.new { |agent|
			agent.user_agent_alias = 'Windows Chrome'
		}

		if @log
			puts '-------------'
		end

		agent.get(@endpoint).links_with(:href => /route=[0-9]/).each_with_index { |link, index|
			service_id = extract_service_id(link)
			status = extract_status(link)
			area = extract_area(link)
			route = extract_route(link)

			service = Service.new(service_id, Time.now.utc, index, area, route, status)

			service_details_page = link.click

			service.disruption_reason = extract_disruption_reason(service_details_page)
			service.disruption_date = extract_disruption_date(service_details_page)
			service.disruption_details = extract_disruption_details(service_details_page)
			service.additional_info = extract_additional_info(service_details_page)

			services << service

			if @log
				puts service
				puts '-------------'
			end

			yield(service) if block_given?

			sleep @service_scrape_delay
		}

		services
	end

	private
	def extract_service_id(link)
		link.href.match(/route=(.+)/i).captures[0].to_i
	end

	def extract_status(link)
		color = link.node.children[1]['src'].split('/').last.split('.').first.split('-').first

		case color
		when 'red' then Service::SAILINGS_CANCELLED
		when 'orange' then Service::SAILINGS_DISRUPTED
		else Service::NORMAL_SERVICE
		end
	end

	def extract_area(link)
		link.node.children[3].text
	end

	def extract_route(link)
		link.node.children[5].text
	end

	def extract_disruption_reason(service_details_page)
		begin
			reason_node_text = service_details_page.search("//p/strong[text()='Reason']").first.parent.text
			reason_node_text.gsub('Reason:', '').strip.gsub(/\b('?[a-z])/) { $1.capitalize }
		rescue
			nil
		end
	end

	def extract_disruption_date(service_details_page)
		begin
			disruption_date_node_text = service_details_page.search("//p/strong[.='Last Updated']").first.parent.text
			disruption_date_string = disruption_date_node_text.gsub('Last Updated:', '').strip
			ActiveSupport::TimeZone['London'].parse(disruption_date_string).utc
		rescue
			nil
		end
	end

	def extract_disruption_details(service_details_page)
		information_node_set = information_node_set(service_details_page)

		disruption_details_nodes = find_nodes_between_keywords('Status', 'Reason', information_node_set)
		if disruption_details_nodes != nil
			disruption_details_nodes.select { |n| n.text.strip != '' }.reduce('') { |output, n| output + n.to_s.strip }
		end
	end

	def extract_additional_info(service_details_page)
		information_node_set = information_node_set(service_details_page)

		additional_info_nodes = find_nodes_between_keywords('Additional Information', 'Timetables', information_node_set)
		if additional_info_nodes != nil
			additional_info_nodes.select { |n| n.text.strip != '' }.reduce('') { |output, n| output + n.to_s.strip }
		end
	end

	def information_node_set(service_details_page)
		service_details_node = find_first_node_containing_text('Service Details', service_details_page.search("//div/h3"))
		service_details_node.parent.children
	end

	def find_first_node_containing_text(text, node_set)
		node_set.select { |n| n.text.strip.include? text }.first
	end

	def find_nodes_between_keywords(keyword1, keyword2, node_set)
		keyword1_node = find_first_node_containing_text(keyword1, node_set)
		keyword1_node_index = node_set.index(keyword1_node)

		keyword2_node = find_first_node_containing_text(keyword2, node_set)
		keyword2_node_index = node_set.index(keyword2_node)

		if keyword1_node_index && keyword2_node_index
			range_start = keyword1_node_index + 1
			range_end = keyword2_node_index - 1
			slice_range = (range_start..range_end)

			node_set.slice(slice_range)
		else
			nil
		end
	end
end

def config(key)
	yaml = YAML.load_file(ARGV[0])
	config = yaml[key]
	database_config = Hash[config.map { |k, v| [k.to_sym, v] }]
end

if __FILE__ == $0
	scraper = Scraper.new()
	scraper.log = true
	scraper.service_scrape_delay = 5

	client = Mysql2::Client.new(config('database'))

	push_service_config = config('parse')

	parse_endpoint = push_service_config[:endpoint]
	parse_applications_id = push_service_config[:application_id]
	parse_rest_api_key = push_service_config[:rest_api_key]

	service_notifier = ServiceNotifier.new(client, ParsePushService.new(parse_endpoint, parse_applications_id, parse_rest_api_key))

	scraper.scrape() { |service|
		begin
			service_notifier.notify_if_required(service)
			service.save(client)
		rescue Exception => e
		 	puts e.message
		 	puts e.backtrace.inspect
		end
	}
end
