# frozen_string_literal: true

module SourceData
  class ExtendedPropertySerializer < ObjectSerializer
    class << self
      delegate(:deserialize_for_insert_all, :deserialize_for_join_insert_all, to: :instance)
    end

    def serialize(property)
      {
        "name" => property.name,
        "friendly_id" => property.friendly_id,
        "values_from" => property.parent_friendly_id,
      }
    end

    def deserialize(hash)
      Property.new(**attributes_from(hash))
    end

    def deserialize_for_insert_all(array)
      array.map { attributes_from(_1) }
    end

    def deserialize_for_join_insert_all(array)
      array.flat_map do |hash|
        property = Property.find_by!(friendly_id: hash["values_from"])
        property.property_values.map do |value|
          {
            property_id: hash["id"],
            property_value_friendly_id: value.friendly_id,
          }
        end
      end
    end

    private

    def attributes_from(hash)
      {
        name: hash["name"],
        friendly_id: hash["friendly_id"],
        parent_friendly_id: hash["values_from"],
      }
    end
  end
end
