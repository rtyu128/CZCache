//
//  CZMemoryCache.h
//  CZCache
//
//  Created by Anchor on 16/5/20.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CZMemoryCache;
typedef void (^CZMemCacheCallBack)(CZMemoryCache *cache);

/**
 CZMemoryCache is a fast memory cache used to store key-value pairs.
 Like YYMemoryCache, CZMemoryCache use LRU(Least Recently Used) to manage key-value pairs,
 support automatically clean key-value pairs or custom operation when receive memory warning
 or App enter background. Also, CZMemoryCache can be managed by count and lifetime.
 
 Differently, You can set lifetime(age) of each key-value pair in CZMemoryCache.
 */
@interface CZMemoryCache <KeyType, ObjectType> : NSObject

// The name of memory cache. Default is nil.
@property (nullable, copy) NSString *name;

// The total count of key-value pairs in memory cache.
@property (readonly) NSInteger totalCount;

/**
 The maximum count of key-valus pairs allowed in memory cache.
 
 @discussion The default value is 50. Set it to NSUIntegerMax means no limit.
 This is not a strict limit, trim queue check the limit every autoTrimInterval.
 */
@property (assign) NSUInteger countLimit;

/**
 The cycle that control auto trim interval(in secends), default is 10.0.
 
 @discussion There is a timer task whick checks its limits and remove expire key-value pairs.
 Set 0.0 to stop the timer task, generally there is no need to stop auto trim.
 */
@property (assign) NSTimeInterval autoTrimInterval;

/**
 Switch to control auto expire clean.
 Default is YES, set NO to disable it.
 
 @discussion If autoTrimInterval has been set to 0.0, the auto expire clean function will be close.
 */
@property (assign) BOOL enableExpireClean;

/**
 Switch to control whether objects release on main thread or on background thread, default is NO.
 
 @discussion If you set objects which should be release on main thread (e.g. UIView), you should set this switch to YES.
 */
@property (assign) BOOL releaseOnMainThread;

/**
 Switch to control whether objects release asynchronously or synchronously, default is YES.
 If set to NO, the access methods may blocking current thread.
 */
@property (assign) BOOL releaseAsynchronously;

/**
 The following properties used to define custom behaviour when receive memory warning or app enter background.
 */
@property (assign) BOOL shouldRemoveAllObjectsWhenMemoryWarning;
@property (assign) BOOL shouldRemoveAllObjectsWhenEnteringBackground;
@property (copy, nullable) CZMemCacheCallBack didReceiveMemoryWarningBlock;
@property (copy, nullable) CZMemCacheCallBack didEnterBackgroundBlock;

/**
 Designated initializer
 
 @return A memory cache instance with `name`.
 */
- (nullable instancetype)initWithName:(nullable NSString *)name NS_DESIGNATED_INITIALIZER;

/**
 Adds a given key-value pair to memory cache, the lifetime will be set to 0.0 which means no limit.
 
 @param object: The value for key. A strong reference to the object is maintained by the memory cache.
                If nil, removeObjectForKey:key will be invoke.
 @param key:    The key for object, If key already exists in the cache, object takes its place.
                If nil, this method makes no effect.
 */
- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key;

/**
 Adds a given key-value pair to memory cache with custom lifetime.
 
 @param object:  The value for key. A strong reference to the object is maintained by the memory cache.
                 If nil, removeObjectForKey:key will be invoke.
 @param key:     The key for object, If key already exists in the cache, object takes its place.
                 If nil, this method makes no effect.
 @param lifetime:The lifetime for key-value pair. If the lifetime is over, correspond key-value pair will be removed.
 */
- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key lifeTime:(NSTimeInterval)lifetime;

/**
 Returns the value associated with a given key.
 The value associated with the key, or nil if no value is associated with the key.
 
 @param key: The key of object which you want to get, if nil return nil.
 */
- (nullable ObjectType)objectForKey:(KeyType)key;

/**
 Returns a boolean value that indicates whether a given key's associated value is in cache.
 
 @param key: The key which you want to check, if nil return NO.
 @return whether the key's associated value is in cache.
 */
- (BOOL)containsObjectForKey:(KeyType)key;

/**
 Removes a given key's associated value from the cache.
 Does nothing if the key does not exist.
 
 @param key: The key of object which you want to remove, if nil does nothing.
 */
- (void)removeObjectForKey:(KeyType)key;

/**
 Empties the cache immediately. Each value object is sent a release message.
 */
- (void)removeAllObjects;

/**
 Removes objects from the cache until the totalCount is below or equal to 
 the specified count.
 
 @param count: The total count of key-value pairs you want the cache to hold.
 */
- (void)trimToCountLimit:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END