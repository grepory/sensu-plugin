require 'sensu-plugin/cli'
require 'json'
require 'socket'

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

    option :graphite,
      :long => "--graphite",
      :boolean => true,
      :default => true

    option :json,
      :long => "--json",
      :boolean => true,
      :default => false

    option :opentsdb,
      :long => "--opentsdb",
      :boolean => true,
      :default => false

    def to_json(metric)
      ::JSON.generate(metric)
    end

    def to_graphite(metric)
      "#{Socket.gethostname}.#{metric[:name]}\t#{metric[:value]}\t#{metric[:timestamp]}\n"
    end

    def to_opentsdb(metric)
      out = "#{metric[:name]}\t#{metric[:timestamp]}\t#{metric[:value]}"
      metric[:tags].each_key do |tag|
        out << "\t#{tag}=#{metric[:tags][tag]}"
      end
      "#{out}\n"
    end

    def output(metric={})
      if config[:json]
        format = method(:to_json)
      elsif config[:opentsdb]
        format = method(:to_opentsdb)
      elsif config[:graphite]
        format = method(:to_graphite)
      end
      
      if metric.length > 0
        m = { }
        m[:timestamp] = Time.now.to_i
        m[:tags] = { }
        m[:tags][:host] = Socket.gethostname
        m.update(metric)
        
        puts format.call(m)
      end
    end
  end
end
