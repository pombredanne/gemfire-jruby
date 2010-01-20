require 'active_support'

import java.lang.System
import java.util.Properties
import com.gemstone.gemfire.distributed.DistributedSystem
import com.gemstone.gemfire.cache.CacheFactory
import com.gemstone.gemfire.cache.AttributesFactory

include Java

module ActiveSupport
  module Cache
    class GemFire < Store
      class CacheException  < StandardError; end 
  
      def initialize(hashOfGemFireProperties)
        properties = Properties.new
        hashOfGemFireProperties.each do |key, value|
          properties.setProperty(key, value)
        end
        @system = DistributedSystem.connect(properties)
      	@cache = CacheFactory.create(@system)
      	@region = @cache.getRegion(System.getProperty("cachingRegionName") || "default")
      rescue CacheException => e
          logger.error("GemfireCache Creation Error (#{e}): #{e.message}")
          false
    	end

      def region
        @region
      end

      def read(key)
        super
        self.region.get(key)
      rescue CacheException => e
          logger.error("GemfireCache Error (#{e}): #{e.message}")
          false
      end

      def write(key, value)
        super
        self.region.put(key, value)
        true
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
        false
      end

      def delete(key)
        super
        self.region.destroy(key)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
        false
      end

      def keys
        super
        self.region.keys.to_a
      end

      def exist?(key)
        super
        self.region.containsKeyOnServer(key)
      end

      def clear
        super
        self.region.clear
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
