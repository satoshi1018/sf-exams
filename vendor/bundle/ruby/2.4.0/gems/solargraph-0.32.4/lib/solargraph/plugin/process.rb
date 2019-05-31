require 'json'

module Solargraph
  module Plugin
    class Process
      def initialize
        @required = []
        post_initialize
      end

      def post_initialize
      end

      def run
        until STDIN.closed?
          input = gets
          break if input.nil?
          args = nil
          begin
            args = JSON.parse(input)
            case args['command']
            when 'require'
              STDOUT.puts do_require args['paths']
            when 'methods'
              STDOUT.puts get_methods args['params']
            when 'constants'
              STDOUT.puts get_constants args['params']
            when 'fqns'
              STDOUT.puts get_fqns args['params']
            else
              STDOUT.puts respond_err "Unrecognized command #{args['command']}"
            end
          rescue JSON::ParserError => e
            STDOUT.puts respond_err "Error parsing input: #{e.message}"
          rescue Exception => e
            STDOUT.puts respond_err "Error processing input: #{e.message}\n#{e.backtrace}"
          end
          STDOUT.flush
        end
      end

      private

      def do_require paths
        errors = []
        paths.each do |p|
          begin
            require p
            @required.push p
          rescue Exception => e
            Solargraph::Logging.logger.info "Failed to require #{p}: #{e.message}"
            errors.push "Failed to require #{p}: #{e.class} #{e.message}"
          end
        end
        if errors.empty?
          respond_ok
        else
          respond_err errors.join('; ')
        end
      end

      def get_methods args
        result = []
        # @type [Class]
        con = find_constant(args['namespace'], args['root'])
        unless con.nil?
          if (args['scope'] == 'class')
            result.concat con.methods if args['with_private']
            result.concat con.public_methods
          elsif (args['scope'] == 'instance')
            result.concat con.instance_methods if args['with_private']
            result.concat con.public_instance_methods
          end
        end
        result.keep_if{|m| m.to_s.match(/^[a-z_]/i)}
        respond_ok (result.uniq.sort.map do |name|
          # @type [Method]
          meth = args['scope'] == 'class' ? con.method(name) : con.instance_method(name)
          {
            name: name,
            parameters: build_parameter_array(meth.parameters)
          }
        end)
      end

      def get_constants args
        result = []
        con = find_constant(args['namespace'], args['root'])
        unless con.nil?
          #result.concat con.constants
          con.constants.each do |c|
            next if c == :Solargraph and !@required.include?('solargraph')
            here = con.const_get(c)
            item = { namespace: con.to_s, name: c.to_s }
            item[:class] = here.class.to_s
            result.push item
          end
        end
        respond_ok result
      end

      def get_fqns args
        con = find_constant(args['namespace'], args['root'])
        respond_ok (con.nil? ? nil : con.to_s)
      end

      def find_constant(namespace, root)
        result = nil
        unless root.empty?
          parts = root.split('::')
          until parts.empty?
            result = inner_find_constant("#{parts.join('::')}::#{namespace}")
            parts.pop
            break unless result.nil?
          end
        end
        result = inner_find_constant(namespace) if result.nil?
        result
      end

      def inner_find_constant(namespace)
        cursor = Object
        parts = namespace.split('::')
        until parts.empty?
          here = parts.shift
          begin
            cursor = cursor.const_get(here)
          rescue NameError
            return nil
          end
        end
        cursor
      end

      def respond_ok data = []
        {
          status: 'ok',
          message: nil,
          data: data
        }.to_json
      end

      def respond_err msg
        {
          status: 'err',
          message: msg,
          data: []
        }.to_json
      end

      def build_parameter_array parameters
        an = 1
        parameters.map do |p|
          if p[0] == :rest
            str = (p[1] ? "*#{p[1]}" : "*args")
          else
            str = (p[1] ? p[1].to_s : "arg#{an}")
            if p[0] == :opt
              str += ' = ?'
            elsif p[0] == :key
              str += ':'
            elsif p[0] == :keyreq
              str += ': ?'
            end
          end
          an += 1
          str
        end
      end
    end
  end
end
