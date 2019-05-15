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
  class NameParameterRequired < StandardError; end
  class InvalidTransaction < StandardError; end
  class DeprecatedArgument < StandardError; end
  class PolicyNotFound < StandardError; end
  class NameParameterRequired < StandardError; end
  class PolicyMalformed < StandardError; end
  class AccessorIdParameterRequired < StandardError; end
  class TokenMalformed < StandardError; end
  class PolicyAlreadyExists < StandardError; end
  class RoleMalformed < StandardError; end
  class RoleNotFound < StandardError; end
end
