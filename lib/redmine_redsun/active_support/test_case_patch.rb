# :nodoc:
module RedmineRedsun
  # :nodoc:
  module ActiveSupport
    # :nodoc:
    module TestCasePatch
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end
      # :nodoc:
      module ClassMethods
        ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session) if Rails.env.test?
      end
    end
  end
end
