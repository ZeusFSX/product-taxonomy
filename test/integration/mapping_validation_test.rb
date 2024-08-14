# frozen_string_literal: true

require_relative "../test_helper"

class MappingValidationTest < ActiveSupport::TestCase
  def setup
    @sys = System.new
    @mappings_json_data = @sys.parse_json("dist/en/integrations/all_mappings.json")
  end

  test "category IDs in mappings are valid" do
    invalid_categories = []
    @mappings_json_data["mappings"].each do |mapping|
      res = validate_mapping_category_ids(mapping["rules"], "input", mapping["input_taxonomy"])
      invalid_categories.concat(res)

      res = validate_mapping_category_ids(mapping["rules"], "output", mapping["output_taxonomy"])
      invalid_categories.concat(res)
    end

    assert invalid_categories.empty?,
      "The following category ids in mappings are invalid:
      #{invalid_categories}"
  end

  test "every Shopify category has corresponding channel mappings" do
    shopify_categories_lack_mappings = []
    @mappings_json_data["mappings"].each do |mapping|
      next unless mapping["input_taxonomy"].include?("shopify")

      all_shopify_category_ids = category_ids_from_taxonomy(mapping["input_taxonomy"])
      next if all_shopify_category_ids.nil?

      unmapped_category_ids = unmapped_category_ids_for_mappings(
        mapping["input_taxonomy"],
        mapping["output_taxonomy"],
      )

      unmapped_category_ids = if !unmapped_category_ids.nil? &&
          all_shopify_category_ids.first.include?("gid://shopify/TaxonomyCategory/")
        unmapped_category_ids.map { |id| "gid://shopify/TaxonomyCategory/#{id}" }.to_set
      end

      shopify_category_ids_from_mappings_input = mapping["rules"]
        .map { _1.dig("input", "category", "id") }
        .to_set

      missing_category_ids = all_shopify_category_ids - shopify_category_ids_from_mappings_input
      unless unmapped_category_ids.nil?
        missing_category_ids -= unmapped_category_ids
      end

      next if missing_category_ids.empty?

      shopify_categories_lack_mappings << {
        input_taxonomy: mapping["input_taxonomy"],
        output_taxonomy: mapping["output_taxonomy"],
        missing_category_ids: missing_category_ids.map { |id| id.split("/").last },
      }
    end

    unless shopify_categories_lack_mappings.empty?
      puts "Shopify Categories are missing mappings for the following integrations:"
      shopify_categories_lack_mappings.each_with_index do |mapping, index|
        puts ""
        puts "[#{index + 1}] #{mapping[:input_taxonomy]} to #{mapping[:output_taxonomy]} (#{mapping[:missing_category_ids].size} missing)"
        mapping[:missing_category_ids].each do |category_id|
          puts " - #{category_id}"
        end
      end
      assert(shopify_categories_lack_mappings.empty?, "Shopify Categories are missing mappings.")
    end
  end

  test "category IDs cannot be presented in the rules input and unmapped_product_category_ids at the same time" do
    overlapped_category_ids_in_mappings = []
    @mappings_json_data["mappings"].each do |mapping|
      category_ids_from_mappings_input = mapping["rules"]
        .map { _1.dig("input", "category", "id").split("/").last }
        .to_set

      unmapped_category_ids = unmapped_category_ids_for_mappings(
        mapping["input_taxonomy"],
        mapping["output_taxonomy"],
      )
      next if unmapped_category_ids.nil?

      overlapped_category_ids = category_ids_from_mappings_input & unmapped_category_ids.to_set
      next if overlapped_category_ids.empty?

      overlapped_category_ids_in_mappings << {
        input_taxonomy: mapping["input_taxonomy"],
        output_taxonomy: mapping["output_taxonomy"],
        overlapped_category_ids: overlapped_category_ids,
      }
    end

    unless overlapped_category_ids_in_mappings.empty?
      puts "Category IDs cannot be presented in both rules input and unmapped_product_category_ids at the same time for the following integrations:"
      overlapped_category_ids_in_mappings.each_with_index do |mapping, index|
        puts ""
        puts "[#{index + 1}] #{mapping[:input_taxonomy]} to #{mapping[:output_taxonomy]} (#{mapping[:overlapped_category_ids].size} overlapped)"
        mapping[:overlapped_category_ids].each do |category_id|
          puts " - #{category_id}"
        end
      end
      assert(
        overlapped_category_ids_in_mappings.empty?,
        "Category IDs cannot be presented in both rules input and unmapped_product_category_ids at the same time for the following integrations.",
      )
    end
  end

  test "Shopify taxonomy version is in consistent between VERSION file and mappings in the /data folder" do
    shopify_taxonomy_version_from_file = "shopify/" + @sys.read_file("VERSION").strip
    mapping_rule_files = @sys.glob("data/integrations/*/*/mappings/*_shopify.yml")
    files_include_inconsistent_shopify_taxonomy_version = []
    mapping_rule_files.each do |file|
      raw_mappings = @sys.parse_yaml(file)
      [raw_mappings["input_taxonomy"], raw_mappings["output_taxonomy"]].each do |taxonomy_version|
        next if !taxonomy_version.include?("shopify") || taxonomy_version.include?("shopify/2022-02")

        next if taxonomy_version == shopify_taxonomy_version_from_file

        files_include_inconsistent_shopify_taxonomy_version << {
          file_path: file,
          taxonomy_version: taxonomy_version,
        }
      end
    end

    unless files_include_inconsistent_shopify_taxonomy_version.empty?
      puts "The Shopify taxonomy version should be #{shopify_taxonomy_version_from_file} based on the VERSION file"
      puts "We detected inconsistent Shopify taxonomy versions in the following mapping files in the /data folder:"
      files_include_inconsistent_shopify_taxonomy_version.each_with_index do |item|
        puts "- mapping file #{item[:file_path]} has inconsistent Shopify taxonomy version #{item[:taxonomy_version]}"
      end
      assert(
        files_include_inconsistent_shopify_taxonomy_version.empty?,
        "Shopify taxonomy version is inconsistent between VERSION file and mappings in the /data folder.",
      )
    end
  end

  def validate_mapping_category_ids(mapping_rules, input_or_output, input_or_output_taxonomy)
    category_ids = category_ids_from_taxonomy(input_or_output_taxonomy)

    return [] if category_ids.nil?

    invalid_category_ids = Set.new

    mapping_rules.each do |rule|
      product_categories = rule[input_or_output]["category"]
      product_categories = [product_categories] unless product_categories.is_a?(Array)

      product_categories.each do |product_category|
        invalid_category_ids.add(product_category["id"]) unless category_ids.include?(product_category["id"])
      end
    end

    if invalid_category_ids.empty?
      []
    else
      [
        {
          taxonomy_version: input_or_output_taxonomy,
          input_or_output: input_or_output,
          category_ids: invalid_category_ids,
        },
      ]
    end
  end

  def category_ids_from_taxonomy(input_or_output_taxonomy)
    if input_or_output_taxonomy.include?("shopify") && !input_or_output_taxonomy.include?("shopify/2022-02")
      categories_json_data = @sys.parse_json("dist/en/categories.json")
      shopify_category_ids = Set.new
      categories_json_data["verticals"].each do |vertical|
        vertical["categories"].each do |category|
          shopify_category_ids.add(category["id"])
        end
      end
      shopify_category_ids
    else
      channel_category_ids = Set.new
      file_path = "data/integrations/#{input_or_output_taxonomy}/full_names.yml"
      channel_taxonomy = @sys.parse_yaml(file_path)
      channel_taxonomy.each do |entry|
        channel_category_ids.add(entry["id"].to_s)
      end
      channel_category_ids
    end
  end

  def unmapped_category_ids_for_mappings(mappings_input_taxonomy, mappings_output_taxonomy)
    integration_mapping_path = if mappings_input_taxonomy.include?("shopify") &&
        mappings_output_taxonomy.include?("shopify")
      integration_version = "shopify/2022-02"
      if mappings_input_taxonomy == "shopify/2022-02"
        "#{integration_version}/mappings/to_shopify.yml"
      else
        "#{integration_version}/mappings/from_shopify.yml"
      end
    elsif mappings_input_taxonomy.include?("shopify")
      integration_version = mappings_output_taxonomy
      "#{integration_version}/mappings/from_shopify.yml"
    else
      integration_version = mappings_input_taxonomy
      "#{integration_version}/mappings/to_shopify.yml"
    end

    file_path = "data/integrations/#{integration_mapping_path}"
    return unless File.exist?(file_path)

    mappings = @sys.parse_yaml(file_path)
    mappings["unmapped_product_category_ids"] if mappings.key?("unmapped_product_category_ids")
  end
end
