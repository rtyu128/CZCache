//
//  CZDiskCache.h
//  CZCache
//  https://github.com/rtyu128/CZCache
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CZDiskCache;
typedef void (^CZCacheNoParamsBlock)(void);
typedef void (^CZDiskCacheObjectBlock)(CZDiskCache *cache, NSString *key, _Nullable id<NSCoding> object, NSTimeInterval remainLife);

/**
 `CZDiskCache` is a thread safe key-value pairs store consist of SQLite and file system. 
 Accepts any object conforming to the `NSCoding` protocol, and archiving is handled by `NSKeyedArchiver`
 or custom archive block. 
 The value will be stored in sqlite database or file according to the value's size (dbStoreThreshold).
 
 `CZDiskCache` can be controlled by count, size and lifetime. It will do clean work and check the limits 
 when app enter background or will terminate. The expire date of key-value pair will be dated so that 
 the expired objects can be clean.
 */
@interface CZDiskCache : NSObject


#pragma mark - Attributes

// The name of the disk cache. The empty string (nil) if no name is specified.
@property (copy, nullable) NSString *name;

// The directory of the disk cache, e.g. "Library/Caches/CachesStorage/StandardCache"
@property (readonly) NSString *path;

/**
 If the value's size (in bytes) is larger than `dbStoreThreshold`, the object will be 
 stored as a file, otherwise the object will be stored in sqlite database.
 
 The default value is 16 * 1024 (16KB).
 */
@property (assign, readonly) NSUInteger dbStoreThreshold;

/**
 The following two attributes used to support custom archive/unarchive the objects
 which do not conform to the `NSCoding` protocol.
 
 The default value is nil which means NSKeyedArchiver/NSKeyedUnarchiver will be used.
 */
@property (nullable, copy) NSData *(^customArchiveBlock)(id object);
@property (nullable, copy) id (^customUnarchiveBlock)(NSData *data);

/**
 The maximum number of key-value pairs allowed on disk. This value is checked every time
 when app enter background or will terminate. The object which has minimum expire date (except CZ_LIVE_FOREVER) 
 will be removed when the countLimit reached.
 
 The default value is NSIntegerMax, which means no limit.
 */
@property NSInteger countLimit;

/**
 The maximum number of bytes allowed on disk. The check behaviour is similar to countLimit.
 
 The default value is NSIntegerMax, which means no limit.
 */
@property NSInteger sizeLimit;


#pragma mark - Initializer

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Call the designated initializer with dbStoreThreshold = 16 * 1024.
 */
- (nullable instancetype)initWithDirectory:(NSString *)directory;

/**
 The designated initializer. Returns a disk cache based on the specified directory.
 
 @param directory: The directory in which the disk cache will write data.
 @param threshold: See the introduction of `dbStoreThreshold` attribute.
 
 @discussion: If the cache instance for the specified directory already exists in memory,
 this method will return it directly instead of creating a new instance.
 */
- (nullable instancetype)initWithDirectory:(NSString *)directory
                          dbStoreThreshold:(NSUInteger)threshold NS_DESIGNATED_INITIALIZER;


#pragma mark - Access Methods

/**
 Returns the object for the specified key, or nil if no object is associated with the key. 
 This method may blocks the calling thread until the object is available.
 
 @param key: The key of object which you want to get, if nil return nil.
 */
- (nullable id<NSCoding>)objectForKey:(NSString *)key;

/**
 Returns the object for the specified key, or nil if no object is associated with the key.
 This method may blocks the calling thread until the object is available.
 
 @param key: The key of object which you want to get, if nil return nil.
 @param remainLife: A pointer used to get the remain life of the key-value pair, if no object 
                    is associated with the key, the pointer will not be operated.
 */
- (nullable id<NSCoding>)objectForKey:(NSString *)key remainLife:(nullable NSTimeInterval *)remainLife;

/**
 Sets the value of the specified key in the disk cache with live forever (`CZ_LIVE_FOREVER`).
 This method may blocks the calling thread until file write finished.
 
 @param object: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param key: The key with which to associate the value. If nil, this method does nothing.
 */
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;

/**
 Sets the value of the specified key in the disk cache, and associates the key-value pair with the 
 specified lifetime (in seconds).This method may blocks the calling thread until file write finished.
 
 @param object: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param key: The key with which to associate the value. If nil, this method does nothing.
 @param lifetime: The life time with which to associate the key-value pair. `CZ_LIVE_FOREVER` means live 
                  forever.
 */
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key lifetime:(NSTimeInterval)lifetime;

/**
 Removes the value of the specified key in the disk cache.
 This method may blocks the calling thread until file delete finished.
 
 @param key: The key identifying the value to be removed, If nil, this method does nothing.
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 Empties the disk cache.
 This method may blocks the calling thread until file delete finished.
 */
- (void)removeAllObjects;

/**
 The number of bytes contained by the disk cache.
 This method may blocks the calling thread until database read finished.
 */
- (NSInteger)totalSize;

/**
 The number of key-value pairs in the disk cache.
 This method may blocks the calling thread until database read finished.
 */
- (NSInteger)totalCount;


#pragma mark - Trim Methods

/**
 Removes objects from the disk cache, expire earliest first, until the `totalSize` is equal to or
 smaller than the specified size. This method may blocks the calling thread until operation finished.
 
 @param size: The `totalSize` of cache will be trimmed equal to or smaller than this value.
 */
- (void)trimToSizeLimit:(NSInteger)size;

/**
 Removes objects from the disk cache, expire earliest first, until the `totalCount` is equal to 
 the specified count. This method may blocks the calling thread until operation finished.
 
 @param count: The `totalCount` of cache will be trimmed equal to this value.
 */
- (void)trimToCountLimit:(NSInteger)count;

@end


#pragma mark - Async Access Methods

@interface CZDiskCache (CZDiskAsyncAccess)

/**
 Returns the object for the specified key, or nil if no object is associated with the key.
 This method returns immediately and will invoke the completion block in background queue
 when the operation finished.
 
 @param key: The key of object which you want to get. If nil, the object will be nil.
 @param completion: A block used to get key-value pair after operation finished.
 */
- (void)objectForKey:(NSString *)key completion:(CZDiskCacheObjectBlock)completion;

/**
 Sets the value of the specified key in the disk cache, and associates the key-value pair with the
 specified lifetime (in seconds). This method returns immediately and will invoke the completion block
 in background queue when the operation finished.
 
 @param object: The object to be stored in the cache. If nil, `removeObjectForKey:key` will be called.
 @param key: The key with which to associate the value. If nil, this method does nothing.
 @param lifetime: The life time with which to associate the key-value pair. `CZ_LIVE_FOREVER` means live
                  forever.
 @param completion: A block used to confirm key-value pair which will be invoked in background queue after
                    operation finished.
 */
- (void)setObject:(id<NSCoding>)object
           forKey:(NSString *)key
         lifetime:(NSTimeInterval)lifetime
       completion:(nullable CZDiskCacheObjectBlock)completion;

/**
 Removes the value of the specified key in the disk cache. This method returns immediately and will 
 invoke the completion block in background queue when the operation finished.
 
 @param key: The key identifying the value to be removed, If nil, this method does nothing.
 @param completion: A block which will be invoked in background queue after operation finished.
 */
- (void)removeObjectForKey:(NSString *)key completion:(nullable void (^)(NSString *key))completion;

/**
 Empties the disk cache asynchronously.
 
 @param completion: A block which will be invoked in background queue after operation finished.
 */
- (void)removeAllObjectsAsync:(nullable CZCacheNoParamsBlock)completion;

@end


#pragma mark - Extended Data

@interface CZDiskCache (CZExtendedData)


// Get extended data from `anObject`.
+ (nullable NSData *)extendedDataForObject:(id)anObject;

/**
 Sets extended data to `anObject`.
 You can set any extended data (e.g. description) to `anObject` before you save `anObject` to 
 the disk cache. The extended data will also be saved with `anObject`. And then use 
 `extendedDataForObject:` to get the extended data.
 
 @param extendedData: The extended data (pass nil to remove).
 @param anObject: The object.
 */
+ (void)setExtendedData:(nullable NSData *)extendedData forObject:(id)anObject;

@end

NS_ASSUME_NONNULL_END