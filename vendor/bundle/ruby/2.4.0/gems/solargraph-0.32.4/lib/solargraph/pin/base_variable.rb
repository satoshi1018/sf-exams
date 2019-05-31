module Solargraph
  module Pin
    class BaseVariable < Base
      include Solargraph::Source::NodeMethods

      attr_reader :context

      attr_reader :assignment

      def initialize location, namespace, name, comments, assignment, literal, context
        super(location, namespace, name, comments)
        @assignment = assignment
        @literal = literal
        @context = context
      end

      def signature
        @signature ||= resolve_node_signature(@assignment)
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      # @return [Integer]
      def symbol_kind
        Solargraph::LanguageServer::SymbolKinds::VARIABLE
      end

      def return_complex_type
        @return_complex_type ||= generate_complex_type
      end

      def nil_assignment?
        return_complex_type.nil?
      end

      def variable?
        true
      end

      def probe api_map
        return ComplexType::UNDEFINED if @assignment.nil?
        chain = Source::NodeChainer.chain(@assignment, filename)
        clip = api_map.clip_at(location.filename, location.range.start)
        locals = clip.locals - [self]
        chain.infer(api_map, ProxyType.anonymous(context), locals)
      end

      def == other
        return false unless super
        assignment == other.assignment
      end

      def try_merge! pin
        return false unless super
        @assignment = pin.assignment
        @return_complex_type = pin.return_complex_type
        true
      end

      private

      def generate_complex_type
        tag = docstring.tag(:type)
        return ComplexType.try_parse(*tag.types) unless tag.nil? || tag.types.nil? || tag.types.empty?
        return ComplexType.try_parse(@literal) unless @literal.nil?
        ComplexType.new
      end
    end
  end
end
