require 'diplomat'

# Usefull usage of Diplomat lib.
module DiplomaticBag
  # Load all module files
  Dir[File.join(__dir__, 'diplomatic_bag', '*.rb')].each { |file| require file }
end
