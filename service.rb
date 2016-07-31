require 'time'

class Service

    NORMAL_SERVICE = 0
    SAILINGS_DISRUPTED = 1
    SAILINGS_CANCELLED = 2
    UNKNOWN = -99

    attr_accessor :service_id, :updated, :sort_order, :area, :route, :status, :additional_info, :disruption_reason, :disruption_date, :disruption_details

    def updated=(value)
    # Make sure that updated is always in utc
    @updated = value.utc
    end

    def self.fetch_all(client)
        services = []
        client.query("SELECT * FROM services").each { |row|
            services << create_service(row)
        }

        services
    end

    def self.fetch(client, id)
        statement = client.prepare('SELECT * FROM services WHERE service_id = ?')
        row = statement.execute(id).first
        create_service(row) if row
    end

    def self.create_service(row)
        # Parse dates as UTC
        updated = row['updated']
        updated += ' UTC' if updated

        disruption_date = row['disruption_date']
        disruption_date += ' UTC' if disruption_date

        service = Service.new(row['service_id'].to_i, Time.strptime(updated, '%Y-%m-%d %H:%M:%S %Z'), row['sort_order'].to_i, row['area'], row['route'], row['status'].to_i)
        service.additional_info = row['additional_info']
        service.disruption_reason = row['disruption_reason']
        service.disruption_date = Time.strptime(disruption_date, '%Y-%m-%d %H:%M:%S %Z') if disruption_date
        service.disruption_details = row['disruption_details']

        if service.updated < Time.now.utc - (30 * 60)
          # If we updated more than 30 mins ago, then set the status as unknown
          service.status = Service::UNKNOWN
        end

        service
    end

    def initialize(service_id, updated = Time.now.utc, sort_order, area, route, status)
        @service_id = service_id
        @updated = updated.utc
        @sort_order = sort_order
        @area = area
        @route = route
        @status = status
    end

    def save(client)
        sql = 'INSERT INTO services (service_id, updated, sort_order, area, route, status, additional_info, disruption_reason, disruption_date, disruption_details) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '\
        'ON DUPLICATE KEY UPDATE updated = ?, sort_order = ?, area = ?, route = ?, status = ?, additional_info = ?, disruption_reason = ?, disruption_date = ?, disruption_details = ?'

        sql_statement = client.prepare(sql)
        sql_statement.execute(@service_id, @updated, @sort_order, @area, @route, @status, @additional_info, @disruption_reason, @disruption_date, @disruption_details, @updated, @sort_order, @area, @route, @status, @additional_info, @disruption_reason, @disruption_date, @disruption_details)
    end

    def to_s
        output = []
        output << "Service ID: #{@service_id}"
        output << "Updated: #{@updated}"
        output << "Sort Order: #{@sort_order}"
        output << "Area: #{@area}"
        output << "Route: #{@route}"
        output << "Status: #{@status}"
        output << "Disruption Reason: #{@disruption_reason}"
        output << "Disruption Date: #{@disruption_date}"
        output << "Disruption Details: #{@disruption_details}"
        output << "Additional info: #{@additional_info}"

        output.join("\n")
    end

end
