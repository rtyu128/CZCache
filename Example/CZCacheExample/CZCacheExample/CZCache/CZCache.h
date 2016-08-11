//
//  CZCache.h
//  CZCache
//  https://github.com/rtyu128/CZCache
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZMemoryCache.h"
#import "CZDiskCache.h"
#import "CZCacheDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Thanks for ibireme and his powerful YYCache:
 https://github.com/ibireme/YYCache
 
 `CZCache` is a collection-like container that stores key-value pairs.
 `CZCache` provides interface to access `CZMemoryCache` and `CZDiskCache`, It use `CZMemoryCache` to hold 
 key-value pairs in small and fast memory cache, and `CZDiskCache` to persisting key-value pairs to a large 
 and slow disk cache.
 Also, `CZMemoryCache` or `CZDiskCache` can be manipulated separately if necessary. See `CZMemoryCache` and
 `CZDiskCache` for more information.
 */
@interface CZCache : NSObject

// The name of the cache. The empty string (nil) if no name is specified.
@property (copy, readonly) NSString *name;

// The storage directory of the disk cache, e.g. "Library/Caches/CachesStorage/StandardCache"
@property (readonly) NSString *storagePath;

// The underlying memory cache, see `CZMemoryCache` for more details.
@property (strong, readonly) CZMemoryCache *memoryCache;

// The underlying disk cache, see `CZDiskCache` for more details.
@property (strong, readonly) CZDiskCache *diskCache;


#pragma mark - Initializer

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Returns the shared defaults cache instance named "StandardCache" and 
 stored in "Library/Caches/CachesStorage/StandardCache" directory.
 */
+ (nullable instancetype)standardCache;

/**
 Convenience initializer for cache in "Caches" directory.
 
 @param name: The name of the cache, used to create storage path.
 */
+ (nullable instancetype)cacheInCachesDirectoryWithName:(NSString *)name;

/**
 Convenience initializer for cache in "Document" directory.
 
 @param name: The name of the cache, used to create storage path.
 */
+ (nullable instancetype)cacheInDocumentDirectoryWithName:(NSString *)name;

/**
 The designated initializer. Returns a cache instance with the specified name and directory.
 The store path of disk cache is "directory/name/~".
 
 @param name: The name of the cache, used to create storage path, can not be nil.
 @param directory: The storeage directory of the cache, if nil the cache will be store in "Caches" directory.
 */
- (nullable instancetype)initWithName:(NSString *)name directory:(nullable NSString *)directory NS_DESIGNATED_INITIALIZER;


#pragma mark - Access Methods

/**
 Returns the object for the specified key, or nil if no object is associated with `aKey`.
 This method may blocks the calling thread until the object is available.
 
 @param aKey: The key of object which you want to get, if nil return nil.
 @return: The object associated with `aKey`, or nil if no object is associated with `aKey`.
 */
- (nullable id<NSCoding>)objectForKey:(NSString *)akey;

/**
 Returns the extended description for `aKey`, or nil if no description is associated with `aKey`.
 This method may blocks the calling thread until the description is get.
 
 @param aKey: The key of object whose description you want to get, if nil return nil.
 @return: The description of the object with the specified key.
 */
- (nullable NSString *)descriptionForKeyValue:(NSString *)aKey;

/**
 Returns the extended data for `aKey`, or nil if no data is associated with `aKey`.
 This method may blocks the calling thread until the extended date is get. 
 See `extendedDataForObject:` and `setExtendedData:forObject:` in `CZDiskCache` for more details.
 
 @param aKey: The key of object whose extended date you want to get, if nil return nil.
 @return: The extended date of the object with the specified key.
 */
- (nullable NSData *)extendedDataForKeyValue:(NSString *)aKey;

/**
 Returns a boolean value indicates whether a given key's associated value is in cache.
 This method may blocks the calling thread until the result is get.
 
 @param aKey: The key which you want to check, if nil return NO.
 @return: whether the key's associated value is in cache.
 */
- (BOOL)containsObjectForKey:(NSString *)aKey;

/**
 Sets the value of the specified key in the cache with live forever (`CZ_LIVE_FOREVER`).
 This method may blocks the calling thread until file write finished.
 
 @param anObject: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param aKey: The key with which to associate the value. If nil, this method does nothing.
 */
- (void)setObject:(nullable id<NSCoding>)anObject forKey:(NSString *)aKey;

/**
 Sets the value of the specified key in the cache with a description.
 This method may blocks the calling thread until file write finished.
 
 @param anObject: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param aKey: The key with which to associate the value. If nil, this method does nothing.
 @param description: The description for this key-value pair.
 */
- (void)setObject:(nullable id<NSCoding>)anObject forKey:(NSString *)aKey description:(nullable NSString *)desc;

/**
 Sets the value of the specified key in the cache with a custom life time.
 This method may blocks the calling thread until file write finished.
 
 @param anObject: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param aKey: The key with which to associate the value. If nil, this method does nothing.
 @param lifetime: The life time of this key-value pair form now (in seconds), set CZ_LIVE_FOREVER means no limit.
 */
- (void)setObject:(nullable id<NSCoding>)anObject forKey:(NSString *)aKey lifeTime:(NSTimeInterval)lifetime;

/**
 Sets the value of the specified key in the cache with a custom life time, and a alternative extended data.
 See `extendedDataForObject:` and `setExtendedData:forObject:` in `CZDiskCache` for more details.
 This method may blocks the calling thread until file write finished.
 
 @param anObject: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param aKey: The key with which to associate the value. If nil, this method does nothing.
 @param lifetime: The life time of this key-value pair form now (in seconds), set CZ_LIVE_FOREVER means no limit.
 @param extendedData: The extended data for this key-value pair.
 */
- (void)setObject:(nullable id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
     extendedData:(nullable NSData *)extendedData;

/**
 Removes the value of the specified key in the cache.
 This method may blocks the calling thread until file delete finished.
 
 @param aKey: The key identifying the value to be removed, If nil, this method does nothing.
 */
- (void)removeObjectForKey:(NSString *)aKey;

/**
 Empties the cache.
 This method will blocks the calling thread until file delete finished.
 */
- (void)removeAllObjects;

/**
 The following two methods used to support subscript access. For example, you can use 
 ```objc
 [CZCache standardCache][aKey];
 ```
 instead of 
 ```objc 
 [[CZCache standardCache] objectForKey:aKey];
 ```
 to get more brief code.
 */
- (nullable id<NSCoding>)objectForKeyedSubscript:(NSString *)aKey;
- (void)setObject:(nullable id<NSCoding>)anObject forKeyedSubscript:(NSString *)aKey;

@end


#pragma mark - Async Access Methods

@interface CZCache (CZCacheAsyncAccess)

typedef void (^CZCacheObjectBlock)(CZCache *cache, NSString *key, _Nullable id<NSCoding> object);

/**
 Returns the object for the specified key, or nil if no object is associated with the key.
 This method returns immediately and will invoke the completion block in background queue
 when the operation finished.
 
 @param aKey: The key of object which you want to get. If nil, the object will be nil.
 @param completion: A block used to get key-value pair after operation finished.
 */
- (void)objectForKey:(NSString *)aKey completion:(CZCacheObjectBlock)completion;

/**
 Returns a boolean value with the block that indicates whether a given key is in cache.
 This method returns immediately and invoke the passed block in background queue
 when the operation finished.
 
 @param aKey: The key which you want to check, if nil return NO.
 @param completion: A block which will be invoked in background queue after operation finished.
 */
- (void)containsObjectForKey:(NSString *)aKey completion:(void(^)(NSString *key, BOOL contains))completion;

/**
 Sets the value of the specified key in the cache, and associates the key-value pair with the
 specified lifetime (in seconds). This method returns immediately and will invoke the completion block
 in background queue when the operation finished.
 
 @param anObject: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param aKey: The key with which to associate the value. If nil, this method does nothing.
 @param lifetime: The life time with which to associate the key-value pair. `CZ_LIVE_FOREVER` means live
                  forever.
 @param completion: A block used to confirm key-value pair which will be invoked in background queue after
                    operation finished.
 */
- (void)setObject:(nullable id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
       completion:(nullable CZCacheObjectBlock)completion;

/**
 Removes the value of the specified key in the cache. This method returns immediately and will
 invoke the completion block in background queue when the operation finished.
 
 @param aKey: The key identifying the value to be removed, If nil, this method does nothing.
 @param completion: A block which will be invoked in background queue after operation finished.
 */
- (void)removeObjectForKey:(NSString *)aKey completion:(nullable void (^)(NSString * key))completion;

/**
 Empties the cache asynchronously.
 
 @param completion: A block which will be invoked in background queue after operation finished.
 */
- (void)removeAllObjectsAsync:(nullable CZCacheNoParamsBlock)completion;

@end

NS_ASSUME_NONNULL_END
