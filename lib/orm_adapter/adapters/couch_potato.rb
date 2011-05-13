require 'couch_potato'
require 'orm_adapter'

module CouchPotato

  module Persistence
    
    class OrmAdapter < ::OrmAdapter::Base
      # Do not consider these to be part of the class list
      def self.except_classes
        @@except_classes ||= []
      end

      # Gets a list of the available models for this adapter
      def self.model_classes
        ObjectSpace.each_object(Class).to_a.select {|klass| klass.ancestors.include? Mongoid::Document}
      end

      # get a list of column names for a given class
      def column_names
        klass.fields.keys
      end

      # @see OrmAdapter::Base#get!
      def get!(id)
        CouchPotato.database.load! wrap_key(id)
      end

      # @see OrmAdapter::Base#get
      def get(id)
        CouchPotato.database.load wrap_key(id)
      end

      # @see OrmAdapter::Base#find_first
      def find_first(options)
        conditions, order = extract_conditions_and_order!(options)

        if conditions.length > 1
          raise "I can not handle more than one condition yet"
        end

        key   = conditions.keys.first
        value = conditions.values.first

        if key == :id
          get value
        else
          view = klass.send("by_#{key}", :key => value.to_s, :limit => 1)
          CouchPotato.database.view(view).first
        end
      end

      # @see OrmAdapter::Base#find_all
      def find_all(options)
        conditions, order = extract_conditions_and_order!(options)

        if conditions.length > 1
          raise "I can not handle more than one condition yet"
        end

        key   = conditions.keys.first
        value = conditions.values.first

        if key == :id
          record = get(value)
          return [record]
        end

        view = klass.send("by_#{key}", :key => value.to_s)
        CouchPotato.database.view(view)
      end

      # @see OrmAdapter::Base#create!
      def create!(attributes)
        klass.create!(attributes)
      end

      protected

      # converts and documents to ids
      def conditions_to_fields(conditions)
        conditions.inject({}) do |fields, (key, value)|
          if value.is_a?(Mongoid::Document) && klass.fields.keys.include?("#{key}_id")
            fields.merge("#{key}_id" => value.id)
          else
            fields.merge(key => value)
          end
        end
      end

    end

  end

  module OrmAdapter
    def self.included(base)
      base.send :extend, ::OrmAdapter::ToAdapter
    end
  end
end
