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
          properties.setProperty(key, value) unless ((key == 'cacheserver-port') || (key == 'region-name') || (key == 'locators' && role == 'client'))
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
      
      def initialize(role, options)      
        # fill the GemFire properties from the options
        self.check_required_options(role, options)
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

      def query(queryString)
        queryService = @region.getAttributes.getPoolName ? PoolManager.find(@region).getQueryService : @cache.getQueryService
        query = queryService.newQuery(queryString)
        result = query.execute
        selectResults?(result) ? toList(result) : result
      end
      
      private :check_required_options, :get_gemfire_properties, :get_server_attributes, :get_client_attributes,:toList, :selectResults?
    end
  end
end
