class Service

  NORMAL_SERVICE = 0
  SAILINGS_DISRUPTED = 1
  SAILINGS_CANCELLED = 2

	attr_accessor :service_id, :updated, :sort_order, :area, :route, :status,
		:additional_info, :disruption_reason, :disruption_date, :disruption_details

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
    service = Service.new(row['service_id'].to_i, row['updated'], row['sort_order'].to_i, row['area'], row['route'], row['status'].to_i)
    service.additional_info = row['additional_info']
    service.disruption_reason = row['disruption_reason']
    service.disruption_date = row['disruption_date']
    service.disruption_details = row['disruption_details']

    service
  end

	def initialize(service_id, updated, sort_order, area, route, status)
		@service_id = service_id
		@updated = updated
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
