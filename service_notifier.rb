require_relative 'service'

class PushServiceInterfaceError < Exception
end

class ServiceNotifier
    CHANNEL_PREFIX = 'S'

    def initialize(conn, push_service)
        raise PushServiceInterfaceError if !push_service.respond_to?(:push)
        @push_service = push_service
        @conn = conn
    end

    def notify_if_required(service)
        db_service = Service.fetch(@conn, service.service_id)

        return if !db_service
        return if db_service.status == service.status
        return if db_service.status == Service::UNKNOWN || service.status == Service::UNKNOWN

        channel = "#{ServiceNotifier::CHANNEL_PREFIX}#{service.service_id}"
        push_message = message(service)

        return if push_message.length == 0

        data = { :alert => push_message, :service_id => service.service_id, :category => 'disruption' }
        @push_service.push(data, [channel]) if push_message.length > 0
    end

    private
    def message(service)
        case service.status
        when Service::NORMAL_SERVICE
            "Normal services have resumed for #{service.route}"
        when Service::SAILINGS_DISRUPTED
            "There is a disruption to the service #{service.route}"
        when Service::SAILINGS_CANCELLED
            "Sailings have been cancelled for #{service.route}"
        else
            ""
        end
    end
end