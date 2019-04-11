# Usefull usage of Diplomat lib: Services functions
module DiplomaticBag
  def self.compute_service_name(s)
    return '/node::health/' if s.nil? || s == ''

    s
  end

  def self.get_all_services_status(options = {})
    result = {}
    services = Diplomat::Health.state('any', options)
    grouped_by_service = services.group_by { |h| compute_service_name(h['ServiceName']) }.values
    grouped_by_service.each do |s|
      grouped_by_status = s.group_by { |h| h['Status'] }.values
      status = {}
      grouped_by_status.each do |state|
        status[state[0]['Status']] = state.count
      end
      service_name = compute_service_name(s[0]['ServiceName'])
      result[service_name] = status
    end
    result
  end

  def self.get_services_list(service, options = {})
    services = Diplomat::Service.get_all(options)
    services.to_h.keys.grep(/#{service}/)
  end

  def self.get_services_info(service, options = {})
    result = []
    services = get_services_list(service, options)
    services.each do |s|
      result << get_service_info(s.to_s, options)
    end
    result
  end
end
