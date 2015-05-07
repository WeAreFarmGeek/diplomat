module Diplomat
  class KeyNotFound < StandardError; end
  class KeyAlreadyExists < StandardError; end
  class EventNotFound < StandardError; end
  class EventAlreadyExists < StandardError; end
  class UnknownStatus < StandardError; end
end
