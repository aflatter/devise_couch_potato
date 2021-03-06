require 'devise'
require 'couch_potato'
require 'devise/orm/couch_potato/schema'
require 'orm_adapter/adapters/couch_potato'

module Devise
  module Orm
    module CouchPotato
      module ClassMethods
        def validates_uniqueness_of(*args)
          options = args.extract_options!
          attrib = args.first.to_s
          
          if self.respond_to?("by_#{attrib}")
            validate "uniqueness_of_#{attrib}".to_sym
            define_method "uniqueness_of_#{attrib}" do
              result = self.class.to_adapter.find_all(attrib => self.send(attrib))
              expected = self.new? ? 0 : 1
              if result.count > expected
                self.errors.add(attrib, options[:message] || :taken)
              end
            end
          else
            Rails.logger.warn "WARNING you tried to validate uniqueness of #{attrib} but no view named 'by_#{attrib}' exists. Validation could not be added."
          end
        end

        def devise_modules_hook!
          create_authentication_views
          yield
          return unless Devise.apply_schema
          devise_modules.each { |m| send(m) if respond_to?(m, true) }
        end
        
        private
        def create_authentication_views
          authentication_keys.each do |key_name|
            view "by_#{key_name}", :key => key_name
          end
      
          view :by_confirmation_token, :key => :confirmation_token
          view :by_authentication_token, :key => :authentication_token
          view :by_reset_password_token, :key => :reset_password_token
          view :by_unlock_token, :key => :unlock_token
        end
        
      end
      
      module InstanceMethods
        def [](key)
          send key
        end
        def []=(key, value)
          send "#{key}=", value
        end
        def save(options = nil)
          ::CouchPotato.database.save_document(self)
        end
        def save!
          ::CouchPotato.database.save_document!(self)
        end
        def update_attributes(attrs)
          self.attributes = attrs
          self.save
        end
      end
  
      def self.included(receiver)
        receiver.extend         ::Devise::Models
        receiver.extend         ClassMethods
        receiver.extend         Schema
        receiver.send(:include, InstanceMethods)
      end
    end
  end
end
