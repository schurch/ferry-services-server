class Vessel
    class Status
        UNDER_WAY_USING_ENGINE = 0
        AT_ANCHOR = 1
        NOT_UNDER_COMMAND = 2
        RESTRICTED_MANEUVERABILITY = 3
        CONSTRAINED_BY_HER_DRAUGHT = 4
        MOORED = 5
        AGROUND = 6
        ENGAGED_IN_FISHING = 7
        UNDER_WAY_SAILING = 8
        RESERVED_FOR_FUTURE_AMENDMENT_1 = 9
        RESERVED_FOR_FUTURE_AMENDMENT_2 = 10
        POWER_DRIVEN_VESSEL_TOWING_ASTERN = 11
        POWER_DRIVEN_VESSEL_PUSHING_AHEAD = 12
        RESERVED_FOR_FUTURE_USE = 13
        AIS_SART = 14
        UNDEFINED = 15
    end

    attr_accessor :mmsi, :updated, :name, :latitude, :longitude, :speed, :course, :status, :location_updated

    def updated=(value)
        # Make sure that updated is always in utc
        @updated = value.utc if value
    end

    def location_updated=(value)
        # Make sure that disruption date is always in utc
        @location_updated = value.utc if value
    end

    def self.fetch_all(client)
        vessels = []
        client.query("SELECT mmsi, updated, name, X(location) as latitude, Y(location) as longitude, speed, course, status, location_updated FROM vessels").each { |row|
            vessels << create_vessel(row)
        }

        vessels
    end

    def self.create_vessel(row)
        vessel = Vessel.new(mmsi: row['mmsi'], updated: Time.at(row['updated']), name: row['name'], latitude: row['latitude'], longitude: row['longitude'], location_updated: Time.at(row['location_updated']))
        vessel.speed = row['speed']
        vessel.course = row['course']
        vessel.status = row['status']

        vessel
    end

    def initialize(mmsi: nil, updated: nil, name: nil, latitude: nil, longitude: nil, location_updated: nil)
        @mmsi = mmsi
        @updated = updated.utc
        @name = name
        @latitude = latitude
        @longitude = longitude
        @status = Vessel::Status::UNDEFINED
        @location_updated = location_updated.utc
    end

    def save(client)
        sql = 'INSERT INTO vessels (mmsi, updated, name, location, speed, course, status, location_updated) VALUES (?, ?, ?, POINT(?, ?), ?, ?, ?, ?) '\
        'ON DUPLICATE KEY UPDATE updated = ?, name = ?, location = POINT(?, ?), speed = ?, course = ?, status = ?, location_updated = ?'

        sql_statement = client.prepare(sql)
        sql_statement.execute(@mmsi, @updated.to_i, @name, @latitude, @longitude, @speed, @course, @status, @location_updated.to_i, @updated.to_i, @name, @latitude, @longitude, @speed, @course, @status, @location_updated.to_i)
    end

    def to_s
        output = []
        output << "MMSI: #{@mmsi}"
        output << "Updated: #{@updated}"
        output << "Name: #{@name}"
        output << "Latitude: #{@latitude}"
        output << "Longitude: #{@longitude}"
        output << "Speed: #{@speed}"
        output << "Heading: #{@heading}"
        output << "Course: #{@course}"
        output << "Status: #{@status}"
        output << "Location updated: #{@location_updated}"

        output.join("\n")
    end
end
