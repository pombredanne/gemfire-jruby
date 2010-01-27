require 'active_support'

import java.lang.System
import java.util.Properties
import com.gemstone.gemfire.distributed.DistributedSystem
import com.gemstone.gemfire.cache.CacheFactory
import com.gemstone.gemfire.cache.AttributesFactory

include Java

module ActiveSupport
  module Cache
    # ActiveSupport::Cache::GemFire creates a Singleton object that provides access to a GemFire cache.
    class GemFire < Store
      class << self; attr_accessor :instance; end
      
      class CacheException  < StandardError; end 
  
    	private_class_method :new
      
    	# GemFire is a Singleton. new() is hidden, so use getInstance() to both create the GemFire instance and to launch GemFire.
    	#   There is an optional Hash that you can use to override any GemFire properties'.
    	#   For example, GemFire.getInstance('locators' => 'localhost[10355]', 'mcast-port' => '0')
    	# Since it is a Singleton, successive calls to GemFire.getInstance() will return the single
    	# instance that was instantiated by the first call.
    	def GemFire.getInstance(hashOfGemFireProperties)
      	self.instance ||= new(hashOfGemFireProperties={})
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
    	end

      # Read a value from the GemFire cache. _key_ can be any JRuby object. Returns the value stored at _key_.
      def read(key)
        super
        @region.get(key)
      rescue CacheException => e
          logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Write a value to the GemFire cache. _key_ is used to read the value from the cache and can be any JRuby object. Returns the value that was stored at _key_.
      def write(key, value)
        super
        @region.put(key, value)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Delete the entry stored in the GemFire cache at _key_. _key_ can be any JRuby object. Returns the value that was deleted.
      def delete(key)
        super
        @region.destroy(key)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Fetch all of the keys currently in the GemFire cache. Returns a JRuby Array of JRuby objects.
      def keys
        @region.keys.to_a
      end

      # Check if there is an entry accessible by _key_ in the GemFire cache. Returns a boolean.
      def exist?(key)
        if @region.getAttributes.getPoolName then
          @region.containsKey(key)
        else
          @region.containsKeyOnServer(key)
        end
      end

      # Delete all entries (key=>value pairs) from the GemFire cache. Returns a JRuby Hash.
      def clear
        @region.clear
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Not implemented by GemFire. Raises an exception when called.
      def increment(key)
        raise "Not supported by Gemfire"
      end

      # Not implemented by GemFire. Raises an exception when called.
      def decrement(key)
        raise "Not supported by Gemfire"
      end

      # Not implemented by GemFire. Raises an exception when called.
      def delete_matched(matcher)
        raise "Not supported by Gemfire"
      end
    end
  end
end
