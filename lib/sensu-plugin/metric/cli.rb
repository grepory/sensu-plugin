require 'sensu-plugin/cli'
require 'json'

module Sensu::Plugin::Metric
  class CLI < Sensu::Plugin::CLI
    class JSON < Sensu::Plugin::CLI
      def output(obj=nil)
        if obj.is_a?(String) || obj.is_a?(Exception)
          puts obj.to_s
        elsif obj.is_a?(Hash)
          obj['timestamp'] ||= Time.now.to_i
          puts ::JSON.generate(obj)
        end
      end
    end

    class Graphite < Sensu::Plugin::CLI
      def output(*args)
        if args[0].is_a?(Exception) || args[1].nil?
          puts args[0].to_s
        else
          args[2] ||= Time.now.to_i
          puts args[0..2].join("\t")
        end
      end
    end

    def initialize
      super
      self.format = method(:to_graphite)
    end

    option :graphite,
      :long => "--graphite",
      :boolean => true,
      :default => false,
      :proc => Proc.new { self.format = method(:to_graphite) }

    option :json,
      :long => "--json",
      :boolean => true,
      :default => false,
      :proc => Proc.new { self.format = method(:to_json) }

    option :opentsdb,
      :long => "--opentsdb",
      :boolean => true,
      :default => false,
      :proc => Proc.new { self.format = method(:to_opentsdb) }

    def to_json(metric)
      metric[:output_type] = 'json'
      ::JSON.generate(metric)
    end

    def to_graphite(metric)
      metric[:output_type] = 'graphite'
      "#{metric[:name]}\t#{metric[:value]}"
    end

    def to_opentsdb(metric)
      metric[:output_type] = 'opentsdb'
      out = "#{metric[:name]}\t#{metric[:timestamp]}\t#{metric[:value]}"
      metric[:tags].each do |tag|
        out << "\t#{tag}=#{metrics[:tags][tag]}"
      end
      out
    end

    def output(metric={})
      metric[:timestamp] ||= Time.now.to_i
      puts self.format(metric)
    end

  end
end
