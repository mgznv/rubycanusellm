# frozen_string_literal: true

require "erb"
require "yaml"

module RubyCanUseLLM
  class Prompt
    VALID_ROLES = %w[system user assistant].freeze

    def initialize(**roles)
      invalid = roles.keys.map(&:to_s) - VALID_ROLES
      unless invalid.empty?
        raise Error, "Invalid role(s): #{invalid.join(", ")}. Valid roles: #{VALID_ROLES.join(", ")}"
      end
      if !roles.key?(:user) && !roles.key?("user")
        raise Error, "Prompt requires at least a :user role"
      end

      @roles = roles.transform_keys(&:to_sym)
    end

    def self.load(path, **variables)
      raise Error, "Prompt file not found: #{path}" unless File.exist?(path)

      data = YAML.safe_load(File.read(path))
      unless data.is_a?(Hash)
        raise Error, "Prompt file must be a YAML hash with role keys (system, user, assistant)"
      end

      roles = data.transform_keys(&:to_sym).slice(*VALID_ROLES.map(&:to_sym))
      new(**roles).render(**variables)
    end

    def render(**variables)
      binding_obj = build_binding(variables)
      @roles.filter_map do |role, template|
        next if template.nil? || template.strip.empty?
        content = ERB.new(template, trim_mode: "-").result(binding_obj)
        { role: role, content: content.strip }
      end
    rescue NameError => e
      raise Error, "Missing variable in prompt template: #{e.message}"
    end

    private

    def build_binding(variables)
      ctx = Object.new
      variables.each do |key, value|
        ctx.define_singleton_method(key) { value }
      end
      ctx.instance_eval { binding }
    end
  end
end
