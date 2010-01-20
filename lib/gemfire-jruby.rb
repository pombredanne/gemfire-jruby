require 'activesupport'

import java.lang.System
import java.util.Properties
import com.gemstone.gemfire.distributed.DistributedSystem
import com.gemstone.gemfire.cache.CacheFactory
import com.gemstone.gemfire.cache.AttributesFactory

include Java

module ActiveSupport
  module Cache
    class GemFire < Store
      class << self; attr_accessor :instance; end
      
      class CacheException  < StandardError; end 
  
    	private_class_method :new
      
    	def GemFire.getInstance(hashOfGemFireProperties)
      	self.instance ||= new(hashOfGemFireProperties)
      end

      def initialize(hashOfGemFireProperties)
        properties = Properties.new
        hashOfGemFireProperties.each do |key, value|
          properties.setProperty(key, value)
        end
        system = DistributedSystem.connect(properties)
      	cache = CacheFactory.create(system)
      	@region = cache.getRegion(System.getProperty("cachingRegionName") || "default")
      rescue CacheException => e
          logger.error("GemfireCache Creation Error (#{e}): #{e.message}")
          false
    	end

      def read(key)
        super
        @region.get(key)
      rescue CacheException => e
          logger.error("GemfireCache Error (#{e}): #{e.message}")
          false
      end

      def write(key, value)
        super
        @region.put(key, value)
        true
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
        false
      end

      def delete(key)
        super
        @region.destroy(key)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
        false
      end

      def keys
        super
        @region.keys.to_a
      end

      def exist?(key)
        super
        @region.containsKeyOnServer(key)
      end

      def clear
        super
        @region.clear
        true
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
        false
      end

      def increment(key)
        raise "Not supported by Gemfire"
      end

      def decrement(key)
        raise "Not supported by Gemfire"
      end

      def delete_matched(matcher)
        raise "Not supported by Gemfire"
      end
    end
  end
end
