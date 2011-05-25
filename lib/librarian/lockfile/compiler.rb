require 'librarian/helpers/debug'

module Librarian
  class Lockfile
    class Compiler

      include Helpers::Debug

      attr_reader :root_module

      def initialize(root_module)
        @root_module = root_module
      end

      def compile(manifests)
        out = StringIO.new
        dsl_class.source_types.map{|t| t[1]}.each do |type|
          type_manifests = manifests.select{|m| type === m.source}
          sources = type_manifests.map{|m| m.source}.uniq.sort_by{|s| s.to_s}
          sources.each do |source|
            source_manifests = type_manifests.select{|m| source == m.source}
            save_source(source, source_manifests) { |s| out.puts s }
          end
        end
        out.rewind
        out.read
      end

    private

      def save_source(source, manifests)
        yield "#{source.class.lock_name}"
        options = source.to_lock_options
        remote = options.delete(:remote)
        yield "  remote: #{remote}"
        options.to_a.sort_by{|a| a[0].to_s}.each do |o|
          yield "  #{o[0]}: #{o[1]}"
        end
        yield "  specs:"
        manifests.sort{|a, b| a.name <=> b.name}.each do |manifest|
          yield "    #{manifest.name} (#{manifest.version})"
          manifest.dependencies.sort{|a, b| a.name <=> b.name}.each do |dependency|
            yield "      #{dependency.name} (#{dependency.requirement})"
          end
        end
        yield ""
      end

      def dsl_class
        root_module.dsl_class
      end

    end
  end
end