# CZCache
A Cache Library like YYCache.

 Thanks for ibireme and his powerful YYCache:  
 https://github.com/ibireme/YYCache
 
 `CZCache` is a collection-like container that stores key-value pairs.
 `CZCache` provides interface to access `CZMemoryCache` and `CZDiskCache`, It use `CZMemoryCache` to hold 
 key-value pairs in small and fast memory cache, and `CZDiskCache` to persisting key-value pairs to a large 
 and slow disk cache.
 
 `CZMemoryCache` is a fast memory cache used to store key-value pairs.
 Like `YYMemoryCache`, `CZMemoryCache` use LRU (Least Recently Used) to manage key-value pairs,
 support automatically clean key-value pairs or custom operation when receive memory warning
 or App enter background. Also, `CZMemoryCache` can be managed by count and lifetime, and is 
 thread safe.
 Differently, You can set lifetime (age) of each key-value pair in `CZMemoryCache`.
 
 `CZDiskCache` is a thread safe key-value pairs store consist of SQLite and file system. 
 Accepts any object conforming to the `NSCoding` protocol, and archiving is handled by `NSKeyedArchiver`
 or custom archive block. 
 The value will be stored in sqlite database or file according to the value's size (dbStoreThreshold).
 
 `CZDiskCache` can be controlled by count, size and lifetime. It will do clean work and check the limits 
 when app enter background or will terminate. The expire date of key-value pair will be dated so that 
 the expired objects can be clean.
