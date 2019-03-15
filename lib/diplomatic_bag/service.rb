# Usefull usage of Diplomat lib: Service functions
module DiplomaticBag
  def self.get_service_info(service, options = {})
    result = {}
    health = Diplomat::Health.service(service, options)
    result[service] = {}
    health.each do |h|
      result[service][h['Node']['Node']] = {
        'Address': h['Node']['Address'],
        'Port': h['Service']['Port']
      }
      checks = {}
      h['Checks'].each do |c|
        checks[c['Name']] = { 'status': c['Status'], 'output': c['Output'] }
      end
      result[service][h['Node']['Node']]['Checks'] = checks
    end
    result
  end
end
