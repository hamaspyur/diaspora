module Diaspora
  module Federated
    module Lint
      MUTE =  true
      REQUIRED_METHODS = %w{
        subscribers
        diaspora_handle
        receive
        to_diaspora_xml
        after_dispatch
        author
        notification_type
      }

      OPTIONAL_METHODS = %w{
        parent
        relayable
      }

      def self.included(model)
        lint_check(model)

        #type check federation methods to make sure they are giving us expected stuff
        model.instance_eval do
            alias_method_chain :receive, :lint
            alias_method_chain :subscribers, :lint
        end
      end

      def self.lint_check(model)
        object = model.new

        [REQUIRED_METHODS, OPTIONAL_METHODS].each do |set|
          unresponsive_methods(object, set).each do |missing_method|
            puts "WARNING: #{model} does not have method:#{missing_method}"
          end
        end
       puts'-------' 
      end

      def self.unresponsive_methods(object, methods)
        methods.find_all do |method|
          !object.respond_to?(method.to_sym) 
        end
      end
 


      #recieve should always return an instance of itself (or nil?????)
      def receive_with_lint(*args)
        object = receive_without_lint(*args)
        #if this object is not returning an instance of itself
        if object.class.to_s != self.class.to_s 
          puts "WARNING: #{self.class.to_s}'s receive is returing object of type: #{object.class.to_s}" unless MUTE
        end
        object
      end

      #subscribers should always return ActiveRecord::Relation
       def subscribers_with_lint(*args)
        subscribers = subscribers_without_lint(*args)
        unless subscribers.class.to_s == 'ActiveRecord::Relation'
          puts "WARNING: #{self.class.to_s}'s subscribers is returning object of type: #{subscribers.class}" unless MUTE
        end

        subscribers
      end
    end
  end
end