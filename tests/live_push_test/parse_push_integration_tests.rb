require_relative '../../service'
require_relative '../../parse_push_service'

RSpec.describe ParsePushService do
  it "pushes to parse on a specific channel" do
    push_service = ParsePushService.new()
    push_service.push({:alert => 'There is a disruption with the service', :category => 'disruption', :service_id => 5}, ['S5'])
  end
end
