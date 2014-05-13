module RedmineRedsun
  module ActiveSupport
    module TestCasePatch
      def self.included(base) # :nodoc:
        base.extend ClassMethods
        #base.send(:include, InstanceMethods)
      end
      module ClassMethods
        ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session) if Rails.env.test?
      end
    end
  end
end