# frozen_string_literal: true

class Property < ApplicationRecord
  default_scope { order(:name) }

  scope :concrete, -> { where(parent_friendly_id: nil) }
  scope :abstract, -> { where.not(parent_friendly_id: nil) }

  has_many :categories_properties, dependent: :destroy, foreign_key: :property_friendly_id, primary_key: :friendly_id
  has_many :categories, through: :categories_properties

  has_many :properties_property_values, dependent: :destroy
  has_many :property_values, through: :properties_property_values, foreign_key: :property_value_friendly_id

  belongs_to :parent,
    class_name: "Property",
    optional: true,
    foreign_key: :parent_friendly_id,
    primary_key: :friendly_id

  has_many :children,
    class_name: "Property",
    foreign_key: :parent_friendly_id,
    primary_key: :friendly_id

  def property_value_friendly_ids=(ids)
    self.property_values = PropertyValue.where(friendly_id: ids)
  end

  validates :name, presence: true

  def gid
    if abstract?
      parent.gid
    else
      "gid://shopify/TaxonomyAttribute/#{id}"
    end
  end

  def name
    if abstract?
      parent.name
    else
      super
    end
  end

  # correct mental model wise, but I wonder on if this hurts other queries we wanna do
  def property_values
    if abstract?
      parent.property_values
    else
      super
    end
  end

  def abstract?
    parent.present?
  end
end
