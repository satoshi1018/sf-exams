module Solargraph
  module Pin
    module YardPin
      class Method < Pin::Method
        include YardMixin

        def initialize code_object, location, name = nil, scope = nil, visibility = nil
          comments = (code_object.docstring ? code_object.docstring.all : nil)
          super(location, code_object.namespace.to_s, name || code_object.name.to_s, comments, scope || code_object.scope, visibility || code_object.visibility, get_parameters(code_object), nil)
        end

        def return_complex_type
          @return_complex_type ||= Solargraph::ComplexType.try_parse(Solargraph::CoreFills::CUSTOM_RETURN_TYPES[path]) if Solargraph::CoreFills::CUSTOM_RETURN_TYPES.has_key?(path)
          super
        end

        private

        def get_parameters code_object
          return [] unless code_object.kind_of?(YARD::CodeObjects::MethodObject)
          args = []
          code_object.parameters.each do |a|
            p = a[0]
            unless a[1].nil?
              p += ' =' unless p.end_with?(':')
              p += " #{a[1]}"
            end
            args.push p
          end
          args
        end
      end
    end
  end
end
