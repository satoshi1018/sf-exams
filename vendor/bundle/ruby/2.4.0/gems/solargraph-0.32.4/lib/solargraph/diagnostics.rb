module Solargraph
  # The Diagnostics library provides reporters for analyzing problems in code
  # and providing the results to language server clients.
  #
  module Diagnostics
    autoload :Base,            'solargraph/diagnostics/base'
    autoload :Severities,      'solargraph/diagnostics/severities'
    autoload :Rubocop,         'solargraph/diagnostics/rubocop'
    autoload :RubocopHelpers,  'solargraph/diagnostics/rubocop_helpers'
    autoload :RequireNotFound, 'solargraph/diagnostics/require_not_found'
    autoload :TypeNotDefined,  'solargraph/diagnostics/type_not_defined'
    autoload :UpdateErrors,    'solargraph/diagnostics/update_errors'

    class << self
      # Add a reporter with a name to identify it in .solargraph.yml files.
      #
      # @param name [String] The name
      # @param klass [Class<Solargraph::Diagnostics::Base>] The class implementation
      # @return [void]
      def register name, klass
        reporter_hash[name] = klass
      end

      # Get an array of reporter names.
      #
      # @return [Array<String>]
      def reporters
        reporter_hash.keys
      end

      # Find a reporter by name.
      #
      # @param name [String] The name with which the reporter was registered
      # @return [Class<Solargraph::Diagnostics::Base>]
      def reporter name
        reporter_hash[name]
      end

      private

      # @return [Hash]
      def reporter_hash
        @reporter_hash ||= {}
      end
    end

    register 'rubocop', Rubocop
    register 'require_not_found', RequireNotFound
    register 'type_not_defined', TypeNotDefined
    register 'update_errors', UpdateErrors
  end
end
