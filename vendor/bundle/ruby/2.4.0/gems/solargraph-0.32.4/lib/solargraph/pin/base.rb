module Solargraph
  module Pin
    # The base class for map pins.
    #
    class Base
      include Conversions
      include Documenting

      # @return [Solargraph::Location]
      attr_reader :location

      # The namespace in which this pin is defined.
      # The root namespace is an empty string.
      #
      # @return [String]
      attr_reader :namespace

      # @return [String]
      attr_reader :name

      # @return [Integer]
      attr_reader :kind

      # @return [String]
      attr_reader :path

      # @param location [Solargraph::Location]
      # @param namespace [String]
      # @param name [String]
      # @param comments [String]
      def initialize location, namespace, name, comments
        @location = location
        @namespace = namespace
        @name = name
        @comments = comments
      end

      # @return [String]
      def comments
        @comments ||= ''
      end

      # @return [String]
      def filename
        return nil if location.nil?
        location.filename
      end

      # @return [Integer]
      def completion_item_kind
        LanguageServer::CompletionItemKinds::KEYWORD
      end

      # @return [Integer]
      def symbol_kind
        nil
      end

      def to_s
        name.to_s
      end

      # @return [Boolean]
      def variable?
        false
      end

      # @return [ComplexType]
      def context
        @context ||= ComplexType.try_parse(namespace || '')
      end

      # Pin equality is determined using the #nearly? method and also
      # requiring both pins to have the same location.
      #
      def == other
        return false unless nearly? other
        comments == other.comments and location == other.location
      end

      # True if the specified pin is a near match to this one. A near match
      # indicates that the pins contain mostly the same data. Any differences
      # between them should not have an impact on the API surface.
      #
      # @param other [Solargraph::Pin::Base, Object]
      # @return [Boolean]
      def nearly? other
        self.class == other.class &&
          namespace == other.namespace &&
          name == other.name &&
          (comments == other.comments ||
            (((maybe_directives? == false && other.maybe_directives? == false) || compare_directives(directives, other.directives)) &&
            compare_docstring_tags(docstring, other.docstring))
          )
      end

      # An alias for return_complex_type.
      #
      # @return [ComplexType]
      def return_type
        return_complex_type
      end

      # All of the pin's return types as an array of ComplexTypes.
      #
      # @return [ComplexType]
      def return_complex_type
        @return_complex_type ||= ComplexType::UNDEFINED
      end

      # @return [YARD::Docstring]
      def docstring
        parse_comments unless defined?(@docstring)
        @docstring ||= Solargraph::Source.parse_docstring('').to_docstring
      end

      # @return [Array<YARD::Tags::Directive>]
      def directives
        parse_comments unless defined?(@directives)
        @directives
      end

      # @return [Array<YARD::Tags::MacroDirective>]
      def macros
        @macros ||= collect_macros
      end

      # Perform a quick check to see if this pin possibly includes YARD
      # directives. This method does not require parsing the comments.
      #
      # After the comments have been parsed, this method will return false if
      # no directives were found, regardless of whether it previously appeared
      # possible.
      #
      # @return [Boolean]
      def maybe_directives?
        return !@directives.empty? if defined?(@directives)
        @maybe_directives ||= comments.include?('@!')
      end

      # @return [Boolean]
      def deprecated?
        @deprecated ||= docstring.has_tag?('deprecated')
      end

      # Get a fully qualified type from the pin's return type.
      #
      # The relative type is determined from YARD documentation (@return,
      # @param, @type, etc.) and its namespaces are fully qualified using the
      # provided ApiMap.
      #
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def typify api_map
        return_complex_type.qualify(api_map, namespace)
      end

      # Infer the pin's return type via static code analysis.
      #
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def probe api_map
        typify api_map
      end

      # @deprecated Use #typify and/or #probe instead
      # @param api_map [ApiMap]
      # @return [ComplexType]
      def infer api_map
        Solargraph::Logging.logger.warn "WARNING: Pin #infer methods are deprecated. Use #typify or #probe instead."
        type = typify(api_map)
        return type unless type.undefined?
        probe api_map
      end

      # Try to merge data from another pin. Merges are only possible if the
      # pins are near matches (see the #nearly? method). The changes should
      # not have any side effects on the API surface.
      #
      # @param pin [Pin::Base] The pin to merge into this one
      # @return [Boolean] True if the pins were merged
      def try_merge! pin
        return false unless nearly?(pin)
        @location = pin.location
        return true if comments == pin.comments
        @comments = pin.comments
        @docstring = pin.docstring
        @return_complex_type = pin.return_complex_type
        @documentation = nil
        @deprecated = nil
        reset_conversions
        true
      end

      def proxied?
        @proxied ||= false
      end

      # Return a proxy for this pin with the specified return type. Other than
      # the return type and the #proxied? setting, the proxy should be a clone
      # of the original.
      #
      # @param return_type [ComplexType]
      # @return [self]
      def proxy return_type
        result = dup
        result.return_complex_type = return_type
        result.proxied = true
        result
      end

      protected

      # @return [Boolean]
      attr_writer :proxied

      # @return [ComplexType]
      attr_writer :return_complex_type

      private

      # @return [void]
      def parse_comments
        if comments.empty?
          @docstring = nil
          @directives = []
        else
          # HACK: Pass a dummy code object to the parser for plugins that
          # expect it not to be nil
          parse = Solargraph::Source.parse_docstring(comments)
          @docstring = parse.to_docstring
          @directives = parse.directives
        end
      end

      # True if two docstrings have the same tags, regardless of any other
      # differences.
      #
      # @param d1 [YARD::Docstring]
      # @param d2 [YARD::Docstring]
      # @return [boolean]
      def compare_docstring_tags d1, d2
        return false if d1.tags.length != d2.tags.length
        d1.tags.each_index do |i|
          return false unless compare_tags(d1.tags[i], d2.tags[i])
        end
        true
      end

      # @param d1 [Array<YARD::Tags::Directive>]
      # @param d2 [Array<YARD::Tags::Directive>]
      # @return [Boolean]
      def compare_directives d1, d2
        return false if d1.length != d2.length
        d1.each_index do |i|
          return false unless compare_tags(d1[i].tag, d2[i].tag)
        end
        true
      end

      # @param t1 [YARD::Tags::Tag]
      # @param t2 [YARD::Tags::Tag]
      # @return [Boolean]
      def compare_tags t1, t2
        t1.class == t2.class &&
          t1.tag_name == t2.tag_name &&
          t1.text == t2.text &&
          t1.name == t2.name &&
          t1.types == t2.types
      end

      # @return [Array<YARD::Tags::Handlers::Directive>]
      def collect_macros
        return [] unless maybe_directives?
        parse = Solargraph::Source.parse_docstring(comments)
        parse.directives.select{ |d| d.tag.tag_name == 'macro' }
      end
    end
  end
end
