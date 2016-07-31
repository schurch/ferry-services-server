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

    attr_accessor :mmsi, :updated, :name, :latitude, :longitude, :speed, :course, :status

    def self.fetch_all(client)
        vessels = []
        client.query("SELECT mmsi, updated, name, X(location) as latitude, Y(location) as longitude, speed, course, status FROM vessels").each { |row|
            vessels << create_vessel(row)
        }

        vessels
    end

    def self.create_vessel(row)
        vessel = Vessel.new(mmsi: row['mmsi'], updated: row['updated'], name: row['name'], latitude: row['latitude'], longitude: row['longitude'])
        vessel.speed = row['speed']
        vessel.course = row['course']
        vessel.status = row['status']

        vessel
    end

    def initialize(mmsi: nil, updated: nil, name: nil, latitude: nil, longitude: nil)
        @mmsi = mmsi
        @updated = updated
        @name = name
        @latitude = latitude
        @longitude = longitude
        @status = Vessel::Status::UNDEFINED
    end

    def save(client)
        sql = 'INSERT INTO vessels (mmsi, updated, name, location, speed, course, status) VALUES (?, ?, ?, POINT(?, ?), ?, ?, ?) '\
        'ON DUPLICATE KEY UPDATE updated = ?, name = ?, location = POINT(?, ?), speed = ?, course = ?, status = ?'

        sql_statement = client.prepare(sql)
        sql_statement.execute(@mmsi, @updated, @name, @latitude, @longitude, @speed, @course, @status, @updated, @name, @latitude, @longitude, @speed, @course, @status)
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

        output.join("\n")
    end
end
