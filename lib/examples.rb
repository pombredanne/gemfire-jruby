# run this in jirb
require 'rubygems'
require 'gemfire-jruby'

## create the server
server = GemFireServer.new('localhost:10355')
# copy and paste the ExampleCacheListener, ExampleCacheWriter and ExampleCacheLoader classes (below) into the server shell

class ExampleCacheListener
  def afterCreate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was created with ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def afterUpdate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was updated to ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def afterDestroy(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was destroyed'
  end
  def afterInvalidate(entryEvent)
  end
  def afterRegionCreate(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was created'
  end
  def afterRegionDestroy(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was destroyed'
  end
  def afterRegionClear(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was cleared'
  end
  def afterRegionInvalidate(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was invalidated'
  end
  def afterRegionLive(regionEvent)
    raise 'Not supported in gemfire-jruby'
  end
  def close
    puts 'CacheListener is closing'
  end
end

class ExampleCacheWriter
  def beforeCreate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' is about to be created with ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def beforeUpdate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' is about to be updated to ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def beforeDestroy(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' is about to be destroyed'
  end
  def beforeRegionDestroy(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' is about to be destroyed'
  end
  def beforeRegionClear(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' is about to be cleared'
  end
  def close
    puts 'CacheWriter is closing'
  end
end

class ExampleCacheLoader
  def load(helper)
    puts 'Loading ' + YAML::load(helper.getKey).to_s 
    'V' + YAML::load(helper.getKey).to_s
  end
  def close
    puts 'CacheLoader is closing'
  end
end

server.addListener(ExampleCacheListener.new)
server.setWriter(ExampleCacheWriter.new)
server.setLoader(ExampleCacheLoader.new)

# Now, in another jirb shell
require 'rubygems'
require 'gemfire-jruby'

## create the client
client = GemFireClient.new('localhost:10355')

# copy and paste the ExampleCacheListener class (below) into the server shell
class ExampleCacheListener
  def afterCreate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was created with ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def afterUpdate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was updated to ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def afterDestroy(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was destroyed'
  end
  def afterInvalidate(entryEvent)
  end
  def afterRegionCreate(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was created'
  end
  def afterRegionDestroy(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was destroyed'
  end
  def afterRegionClear(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was cleared'
  end
  def afterRegionInvalidate(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was invalidated'
  end
  def afterRegionLive(regionEvent)
    raise 'Not supported in gemfire-jruby'
  end
  def close
    puts 'CacheListener is closing'
  end
end

client.addListener(ExampleCacheListener.new)

# Put some data into the client shell ... the listeners should fire in both shells
(1..12).each do |key| client.write(key, Date.new(key,key,key)) end

# Explore the client memcached api in the client shell
client.read(1)
client.keys
client.exist?(1)

# Now some of the GemFire api
client.create(200,200)
client.put(200,200)
client.invalidate(200)
client.destroy(200)

# Try the server memcached api in the server shell
server.read(1)
server.keys
server.exist?(1)

# Now the server GemFire api
server.create(200,200)
server.put(200,200)
server.invalidate(200)
server.destroy(200)

# Back in the client shell
client.delete(1)
client.exist?(1)
client.clear

# Check in the server shell
server.create(100,100)
server.exist?(100)
server.clear

class ExampleCacheListener
  def afterCreate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was created with ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def afterUpdate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was updated to ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def afterDestroy(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was destroyed'
  end
  def afterInvalidate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' was invalidated'
  end
  def afterRegionCreate(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was created'
  end
  def afterRegionDestroy(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was destroyed'
  end
  def afterRegionClear(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was cleared'
  end
  def afterRegionInvalidate(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' was invalidated'
  end
  def afterRegionLive(regionEvent)
    raise 'Not supported in gemfire-jruby'
  end
  def close
    puts 'CacheListener is closing'
  end
end

class ExampleCacheWriter
  def beforeCreate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' is about to be created with ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def beforeUpdate(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' is about to be updated to ' + YAML::load(entryEvent.getNewValue).to_s
  end
  def beforeDestroy(entryEvent)
    puts YAML::load(entryEvent.getKey).to_s + ' is about to be destroyed'
  end
  def beforeRegionDestroy(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' is about to be destroyed'
  end
  def beforeRegionClear(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + ' is about to be cleared'
  end
  def close
    puts 'CacheWriter is closing'
  end
end

class ExampleCacheLoader
  def load(helper)
    puts 'Loading ' + YAML::load(helper.getKey).to_s 
    'V' + YAML::load(helper.getKey).to_s
  end
  def close
    puts 'CacheLoader is closing'
  end
end


