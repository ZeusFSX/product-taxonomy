# frozen_string_literal: true

# TODO: add params to control what gets synced
class SyncEnLocalizationsCommand < ApplicationCommand
  usage do
    no_command
  end

  def execute
    frame("Syncing EN localizations") do
      sync_categories
      sync_attributes
      sync_values
    end
  end

  private

  def sync_categories
    spinner("Syncing categories") do |sp|
      localizations = Category.as_json_for_localization(Category.all)
      write_localizations("categories", localizations, sp)
    end
  end

  def sync_attributes
    spinner("Syncing attributes") do |sp|
      localizations = Attribute.as_json_for_localization(Attribute.all)
      write_localizations("attributes", localizations, sp)
    end
  end

  def sync_values
    spinner("Syncing values") do |sp|
      localizations = Value.as_json_for_localization(Value.all)
      write_localizations("values", localizations, sp)
    end
  end

  def write_localizations(type, localizations, sp)
    file_path = "data/localizations/#{type}/en.yml"
    sys.write_file!(file_path) do |file|
      file.puts "# This file is auto-generated using bin/sync_en_localizations. Do not edit directly."
      file.write(localizations.to_yaml(line_width: -1))
    end
    sp.update_title("Wrote #{type} localizations to #{file_path}")
  end
end
