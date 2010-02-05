require 'active_support'

import java.lang.System
import java.util.Properties
import com.gemstone.gemfire.distributed.DistributedSystem
import com.gemstone.gemfire.cache.CacheFactory
import com.gemstone.gemfire.cache.AttributesFactory
import com.gemstone.gemfire.cache.client.PoolManager
import com.gemstone.gemfire.cache.DataPolicy
import com.gemstone.gemfire.cache.Scope

include Java

module ActiveSupport
  module Cache
    # ActiveSupport::Cache::GemFire creates a Singleton object that provides access to a GemFire cache.
    class GemFire < Store
      class << self; attr_accessor :instance; end
      
      class CacheException  < StandardError; end 
  
    	private_class_method :new
      
    	# GemFire is a Singleton. new() is hidden, so use getInstance() to both create the GemFire instance and to launch GemFire.
    	#   The required Hash is used to configure clients and servers.
    	#   For example, GemFire.getInstance('server', {'region-name'=> 'data', 'locators' => 'localhost:10355'})
    	# Since it is a Singleton, successive calls to GemFire.getInstance() will return the single
    	# instance that was instantiated by the first call.
      def GemFire.getInstance(role, options={})
      	self.instance ||= new(role, options)
      end

      def initialize(role, options)      
        @role = role
        # fill the GemFire properties from the options
        check_required_options(role, options)
        # join the distributed system
        properties = get_gemfire_properties(role, options)
        system = DistributedSystem.connect(properties)
      	# create the cache ... this will read a cache.xml
      	@cache = CacheFactory.create(system)
        # there is only one region
        regionAttributes = nil
      	if(role == 'client') then
      	  # it's a client
      	  regionAttributes = get_client_attributes(options)
      	else
      	  # it's a server
          cacheServer = @cache.addCacheServer
          cacheServer.setPort(options['cacheserver-port'])
          cacheServer.start
      	  regionAttributes = get_server_attributes(options)
      	end 
      	@region = @cache.createRegion(options['region-name'], regionAttributes)
      rescue CacheException => e
          logger.error("GemfireCache Creation Error (#{e}): #{e.message}")
    	end

      # GemFire api
      def create(key, value)
        @region.create(key.to_yaml, value.to_yaml)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      def put(key, value)
        @region.put(key.to_yaml, value.to_yaml)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      def invalidate(key)
        @region.invalidate(key.to_yaml)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      #  Destroy the entry stored in the GemFire cache at _key_. _key_ can be any JRuby object. Returns the value that was deleted.
      def destroy(key)
        @region.destroy(key.to_yaml)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Read a value from the GemFire cache. _key_ can be any JRuby object. Returns the value stored at _key_.
      def read(key)
        super
        YAML::load(@region.get(key.to_yaml))
      rescue CacheException => e
          logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Alias for put(key, value) ... for compatibility with memcached
      def write(key, value)
        super
        @region.put(key.to_yaml, value.to_yaml)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Alias for destroy(key) ... for compatibility with memcached
      def delete(key)
        super
        @region.destroy(key.to_yaml)
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end

      # Fetch all of the keys. Optional argument controls whether the keys come from the server orReturns a JRuby Array of JRuby objects.
      def keys(onServer=true)
        keySet = nil
        result = []
        if (onServer && (@role == 'client')) then
          keySet = @region.keySetOnServer
        else
          keySet = @region.keySet
        end
        keySet.each do |k| result << YAML::load(k) end
        result
      end

      # Check if there is an entry accessible by _key_ in the GemFire cache. Returns a boolean.
      def exist?(key)
        if @region.getAttributes.getPoolName then
          @region.containsKeyOnServer(key.to_yaml)
        else
          @region.containsKey(key.to_yaml)
        end
      end

      # Delete all entries (key=>value pairs) from the GemFire cache. Returns a JRuby Hash.
      def clear
        @region.clear
      rescue CacheException => e
        logger.error("GemfireCache Error (#{e}): #{e.message}")
      end
      
      # Add and remove CacheListeners to the cache region
      def addListener(cacheListener)
        @region.getAttributesMutator.addCacheListener(cacheListener)
      end

      def removeListener(cacheListener)
        @region.getAttributesMutator.removeCacheListener(cacheListener)
      end

      # Install a CacheWriter into the client's cache region
      def setWriter(cacheWriter)
        if @role == 'server' then
          @region.getAttributesMutator.setCacheWriter(cacheWriter)
        else
          raise 'Only servers can have CacheWriters'
        end
      end

      # Install a CacheLoader into the cache region
      def setLoader(cacheLoader)
        if @role == 'server' then
          @region.getAttributesMutator.setCacheLoader(cacheLoader)
        else
          raise 'Only servers can have CacheLoaders'
        end
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
      
      private
      def check_required_options(role, options)
        # role must be client or server
        if(role != 'client' && role != 'server') then
          raise "The member role must be either client or server"
        end
        # ensure that we are using locators ... no multicast distribution is allowed
        if (!options.include?('locators')) then
          raise "Locators must be specified in the options"
        end
        if (role == 'server' && !options.include?('cacheserver-port')) then
            raise "The server must have a cacheserver-port specified in the options"
          end          
        if (!options.include?('region-name')) then
          raise "The region name must be specified in the options"
        end
      end
      
      def get_gemfire_properties(role, options)
        properties = Properties.new
        properties.setProperty('mcast-port', '0')
        options.each do |key, value|
          puts key
          properties.setProperty(key, value) unless ((key == 'cacheserver-port') || (key == 'region-name') || (key == 'caching-enabled') || (key == 'locators' && role == 'client'))
        end
        properties
      end
      
      def get_client_attributes(options)
        # configure the region attributes for client usage
        attributesFactory = AttributesFactory.new
        # clients have a Pool
        poolFactory = PoolManager.createFactory
        ipAndPort = options['locators'].split(':')
        puts ipAndPort[0]
        puts ipAndPort[1]
        poolFactory.addLocator(ipAndPort[0], ipAndPort[1].to_i)
        poolFactory.create("clientPool")
        # clients do no peer-to-peer distribution
        attributesFactory.setScope(Scope::LOCAL)
        # clients either cache data locally (DataPolicy::NORMAL) or not (DataPolicy::EMPTY)
        if (options['caching-enabled'] == 'true') then
          attributesFactory.setDataPolicy(DataPolicy::NORMAL)
        else
          attributesFactory.setDataPolicy(DataPolicy::EMPTY)
        end
        attributesFactory.setPoolName("clientPool")
  	    regionAttributes = attributesFactory.create
      end
      
      def get_server_attributes(options)
        attributesFactory = AttributesFactory.new
    	  if (options['data-policy'] == 'partition') then
	        # it's a partitioned region
	        attributesFactory.setDataPolicy(DataPolicy::PARTITION)
    	    if (options['redundant-copies']) then
      	    partitionAttributesFactory = PartitionAttributesFactory.new
  	        partitionattributesFactory.setRedundantCopies(options['redundant-copies'].to_s)
  	        partitionAttributes = partitionAttributesFactory.create
  	        attributesFactory.setPartitionAttributes(partitionAttributes)
	        end
    	  elsif (!options['data-policy'] || (options['data-policy'] == 'replicate'))
	        # it's a replicate region
    	    attributesFactory.setDataPolicy(DataPolicy::REPLICATE)
    	  else
    	    raise "Data policy must be either 'replicate', 'partition', or unset (the default is replicate)"
  	    end
  	    regionAttributes = attributesFactory.create
      end
      
      def toList(selectResults)
      	results = []
      	iterator = selectResults.iterator
      	while(iterator.hasNext)
      		results << iterator.next
      	end
      	results	
      end

      def selectResults?(javaObject)
        found = false
        javaObject.getClass.getInterfaces.each { |i|
          if (i.to_s == 'interface com.gemstone.gemfire.cache.query.SelectResults') then
              found = true
          end
        }
        found
      end
    end
  end
end

class GemFireCacher
  def initialize(locator, regionName="data", cachingOn=false)
    raise "GemFireCacher is an abstract class. Instantiate either a GemFireClient or a GemFireServer"
  end
  
  # GemFire api
  def create(key, value)
    @gemfire.create(key, value)
  end
  def put(key, value)
    @gemfire.put(key, value)
  end
  def invalidate(key)
    @gemfire.invalidate(key)
  end
  def destroy(key)
    @gemfire.destroy(key)
  end

  # Both servers and clients can have CacheListeners
  def addListener(cacheListener)
    @gemfire.addListener(cacheListener)
  end

  def removeListener(cacheListener)
    @gemfire.removeListener(cacheListener)
  end

  # Memcached api
  def read(key)
    @gemfire.read(key)
  end
  def write(key, value)
    @gemfire.write(key, value)
  end
  def delete(key)
    @gemfire.delete(key)
  end
  def exist?(key)
    @gemfire.exist?(key)
  end
  def keys(onServer=true)
    @gemfire.keys(onServer)
  end
  def clear
    @gemfire.clear
  end
  def increment(key)
    @gemfire.increment(key)
  end
  def decrement(key)
    @gemfire.decrement(key)
  end
  def delete_matched(matcher)
    @gemfire.delete_matched(matcher)
  end
end

class GemFireServer < GemFireCacher
  def initialize(locator, regionName="data", cacheServerPort=40404)
    @gemfire = ActiveSupport::Cache::GemFire.getInstance('server', {'locators'=>locator, 'region-name'=>regionName, 'cacheserver-port'=>cacheServerPort})
  end  
  # Only servers can have CacheLoaders and CacheWriters
  def setWriter(cacheWriter)
    @gemfire.setWriter(cacheWriter)
  end
  def setLoader(cacheLoader)
    @gemfire.setLoader(cacheLoader)
  end
end

class GemFireClient < GemFireCacher
  def initialize(locator, regionName="data", cachingOn=false)
    @gemfire = ActiveSupport::Cache::GemFire.getInstance('client', {'locators'=>locator, 'region-name'=>regionName, 'caching-enabled'=>cachingOn.to_s})
  end  
end

