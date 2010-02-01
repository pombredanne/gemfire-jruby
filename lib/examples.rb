class ExampleCacheListener
  def afterCreate(entryEvent)
    puts entryEvent.getKey
    puts entryEvent.getNewValue
    puts Marshal.load(entryEvent.getKey).to_s + ' was created with ' + Marshal.load(entryEvent.getNewValue).to_s
  end
  def afterUpdate(entryEvent)
    puts Marshal.load(entryEvent.getKey).to_s + ' was updated to ' + Marshal.load(entryEvent.getNewValue).to_s
  end
  def afterDestroy(entryEvent)
    puts Marshal.load(entryEvent.getKey).to_s + 'was destroyed'
  end
  def afterInvalidate(entryEvent)
  end
  def afterRegionCreate(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + 'was created'
  end
  def afterRegionDestroy(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + 'was destroyed'
  end
  def afterRegionClear(regionEvent)
    puts 'Region ' + regionEvent.getRegion.getName + 'was cleared'
  end
  def afterRegionInvalidate(regionEvent)
  end
  def afterRegionLive(regionEvent)
  end
  def close
    puts 'CacheListener is closing'
  end
end

class ExampleCacheWriter
  def beforeCreate(entryEvent)
    puts entryEvent.getKey
    puts entryEvent.getNewValue
    puts Marshal.load(entryEvent.getKey).to_s + ' is about to be created with ' + Marshal.load(entryEvent.getNewValue).to_s
  end
  def beforeUpdate(entryEvent)
    puts Marshal.load(entryEvent.getKey).to_s + ' is about to be updated to ' + Marshal.load(entryEvent.getNewValue).to_s
  end
  def beforeDestroy(entryEvent)
    puts Marshal.load(entryEvent.getKey).to_s + ' is about to be destroyed'
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
    puts 'Loading ' + Marshal.load(helper.getKey).to_s 
    'V' + Marshal.load(helper.getKey).to_s
  end
  def close
    puts 'CacheLoader is closing'
  end
end

#require 'rubygems'
#require 'lib/gemfire-jruby'

#server = GemFireServer.new('localhost:10355')
#server.addListener(ExampleCacheListener.new)
#server.write(100, {'hello' => 'world', 'goodbye' => 'life'})
