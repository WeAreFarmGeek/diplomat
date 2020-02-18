# frozen_string_literal: true

# Usefull usage of Diplomat lib: Datacenter functions
module DiplomaticBag
  def self.get_datacenters_list(dc, options = {})
    dcs = []
    datacenters = Diplomat::Datacenter.get(nil, options)
    dc.each do |c|
      dcs.concat(datacenters.select { |d| d[/#{c}/] })
    end
    dcs.uniq
  end
end
