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

            service = Service.new(service_id, index, area, route, status)

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
        status = link.attributes.search('img[@alt]').first.attributes['alt'].value

        case status
        when 'CANCELLED' then Service::SAILINGS_CANCELLED
        when 'AFFECTED' then Service::SAILINGS_DISRUPTED
        when 'BEWARE' then Service::SAILINGS_DISRUPTED
        when 'NORMAL' then Service::NORMAL_SERVICE
        else Service::UNKNOWN
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
            reason_text = service_details_page.search("//p/strong[text()='Reason']").first.parent.text
            reason_text.gsub('Reason:', '').strip.gsub(/\b('?[a-z])/) { $1.capitalize }
        rescue
            nil
        end
    end

    def extract_disruption_date(service_details_page)
        begin
            last_updated_text = service_details_page.search("//p/strong[.='Last Updated']").first.parent.text
            last_updated_text_string = last_updated_text.gsub('Last Updated:', '').strip
            ActiveSupport::TimeZone['London'].parse(last_updated_text_string)
        rescue
            nil
        end
    end

    def extract_disruption_details(service_details_page)
        service_updates = service_details_page.search("//h3[.='Service updates']").first
        if service_updates != nil
            service_updates_section = service_updates.parent
            first_index = 3
            last_index = service_updates_section.children.length - 5
            service_details_html = service_updates_section.children[first_index..last_index]
            clean_output(service_details_html)
        end
    end

    def extract_additional_info(service_details_page)
        additional_info_html = service_details_page.search("div.supplementary").children.drop(6)
        clean_output(additional_info_html)
    end

    def clean_output(input)
        input.select { |n| n.text.strip != '' }.reduce('') { |output, n| output + n.to_s.strip }
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
            # service_notifier.notify_if_required(service)
            service.save(client)
        rescue Exception => e
            puts e.message
            puts e.backtrace.inspect
        end
    }
end
