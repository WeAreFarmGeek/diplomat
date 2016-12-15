module Diplomat
  class KeyNotFound < StandardError; end
  class PathNotFound < StandardError; end
  class KeyAlreadyExists < StandardError; end
  class AclNotFound < StandardError; end
  class AclAlreadyExists < StandardError; end
  class EventNotFound < StandardError; end
  class EventAlreadyExists < StandardError; end
  class QueryNotFound < StandardError; end
  class QueryAlreadyExists < StandardError; end
  class UnknownStatus < StandardError; end
  class IdParameterRequired < StandardError; end
end
