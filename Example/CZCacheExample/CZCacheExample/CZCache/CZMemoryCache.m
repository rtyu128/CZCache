//
//  CZMemoryCache.m
//  CZCache
//  https://github.com/rtyu128/CZCache
//  Created by Anchor on 16/5/20.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CZMemoryCache.h"
#import "CZCacheDefines.h"
#import <pthread.h>

@interface CacheKVNode : NSObject {
    @package
    id key;
    id value;
    CFTimeInterval expireDate;
    __unsafe_unretained CacheKVNode *prev;
    __unsafe_unretained CacheKVNode *next;
}
@end

@implementation CacheKVNode
@end



@interface CacheDoublyLinkedList : NSObject {
    @package
    NSUInteger totalCount;
    CacheKVNode *head;
    CacheKVNode *tail;
}

- (void)insertNodeAtHead:(CacheKVNode *)node;

- (void)bringNodeToHead:(CacheKVNode *)node;

- (void)removeNode:(CacheKVNode *)node;

- (CacheKVNode *)removeTailNode;

- (void)removeAllNode;

@end

@implementation CacheDoublyLinkedList

- (void)insertNodeAtHead:(CacheKVNode *)node
{
    totalCount ++;
    if (head) {
        node->next = head;
        head->prev = node;
        head = node;
    } else {
        head = node;
        tail = node;
    }
}

- (void)bringNodeToHead:(CacheKVNode *)node
{
    if (node == head) {
        return;
    } else if (node == tail) {
        tail = tail->prev;
        tail->next = nil;
    } else {
        node->prev->next = node->next;
        node->next->prev = node->prev;
    }
    
    node->next = head;
    node->prev = nil;
    head->prev = node;
    head = node;
}

- (void)removeNode:(CacheKVNode *)node
{
    totalCount --;
    if (node->next) node->next->prev = node->prev;
    if (node->prev) node->prev->next = node->next;
    if (node == head) head = node->next;
    if (node == tail) tail = node->prev;
}

- (CacheKVNode *)removeTailNode
{
    if (!tail) {
        return nil;
    }
    
    totalCount --;
    CacheKVNode *tmpTail = tail;
    if (head == tail) {
        head = nil;
        tail = nil;
    } else {
        tail = tail->prev;
        tail->next = nil;
    }
    return tmpTail;
}

- (void)removeAllNode
{
    totalCount = 0;
    head = nil;
    tail = nil;
}

@end


static const NSUInteger kMCDefaultCountLimit = 50;//NSUIntegerMax
static const NSTimeInterval kMCDefaultAutoTrimInterval = 10.0;


#pragma mark - CZMemoryCache Implementation

@implementation CZMemoryCache {
    pthread_mutex_t mutexLock;
    CacheDoublyLinkedList *list;
    CFMutableDictionaryRef dict;
    dispatch_queue_t trimQueue;
    BOOL autoTrimSwitch;
    BOOL _releaseOnMainThread;
    BOOL _releaseAsynchronously;
    NSTimeInterval _autoTrimInterval;
}


#pragma mark - Life Cycle

- (instancetype)init
{
    return [self initWithName:nil];
}

- (instancetype)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = [name copy];
        _countLimit = kMCDefaultCountLimit;
        autoTrimSwitch = YES;
        _autoTrimInterval = kMCDefaultAutoTrimInterval;
        _enableExpireClean = YES;
        _releaseOnMainThread = NO;
        _releaseAsynchronously = YES;
        _shouldRemoveAllObjectsWhenMemoryWarning = YES;
        _shouldRemoveAllObjectsWhenEnteringBackground = YES;
        
        pthread_mutex_init(&mutexLock, NULL);
        list = [[CacheDoublyLinkedList alloc] init];
        dict = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        trimQueue = dispatch_queue_create("com.netease.memory", DISPATCH_QUEUE_SERIAL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarningNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackgroundNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [self autoTrim];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [list removeAllNode];
    CFRelease(dict);
    pthread_mutex_destroy(&mutexLock);
}


#pragma mark - Public
#pragma mark - Access Methods

- (void)setObject:(nullable id)object forKey:(id)key
{
    [self setObject:object forKey:key lifeTime:CZ_LIVE_FOREVER];
}

- (void)setObject:(id)object forKey:(id)key lifeTime:(NSTimeInterval)lifetime
{
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return ;
    }
    
    pthread_mutex_lock(&mutexLock);
    CacheKVNode *node = CFDictionaryGetValue(dict, (__bridge const void *)key);
    CFTimeInterval now = CACurrentMediaTime();
    if (node) {
        node->value = object;
        node->expireDate = lifetime > 0 ? (now + lifetime) : 0;
        [list bringNodeToHead:node];
    } else {
        node = [[CacheKVNode alloc] init];
        node->key = key;
        node->value = object;
        node->expireDate = lifetime > 0 ? (now + lifetime) : 0;
        CFDictionarySetValue(dict, (__bridge const void *)key, (__bridge const void *)node);
        [list insertNodeAtHead:node];
    }
    
    if (list->totalCount > _countLimit) {
        CacheKVNode *node = [list removeTailNode];
        CFDictionaryRemoveValue(dict, (__bridge const void *)node->key);
        if (_releaseAsynchronously) {
            dispatch_queue_t queue = _releaseOnMainThread ?
            dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            dispatch_async(queue, ^{
                [node class];
            });
        } else if (_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class];
            });
        }
    }
    pthread_mutex_unlock(&mutexLock);
}

- (id)objectForKey:(id)key
{
    if (!key) return nil;
    BOOL invalid = NO;
    pthread_mutex_lock(&mutexLock);
    CacheKVNode *node = CFDictionaryGetValue(dict, (__bridge const void *)key);
    if (node) {
        if (0 == node->expireDate || CACurrentMediaTime() <= node->expireDate) {
            [list bringNodeToHead:node];
        } else {
            node = nil;
            invalid = YES;
        }
    }
    pthread_mutex_unlock(&mutexLock);
    
    if (invalid) [self removeObjectForKey:key];
    return node ? node->value : nil;
}

- (BOOL)containsObjectForKey:(id)key
{
    return [self objectForKey:key] ? YES : NO;
}

- (void)removeObjectForKey:(id)key
{
    if (!key) return;
    pthread_mutex_lock(&mutexLock);
    CacheKVNode *node = CFDictionaryGetValue(dict, (__bridge const void *)key);
    if (node) {
        CFDictionaryRemoveValue(dict, (__bridge const void *)key);
        [list removeNode:node];
        if (_releaseAsynchronously) {
            dispatch_queue_t queue = _releaseOnMainThread ?
            dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            dispatch_async(queue, ^{
                [node class];
            });
        } else if (_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class];
            });
        }
    }
    pthread_mutex_unlock(&mutexLock);
}

- (void)removeAllObjects
{
    pthread_mutex_lock(&mutexLock);
    [self removeAllData];
    pthread_mutex_unlock(&mutexLock);
}

- (void)trimToCountLimit:(NSUInteger)count
{
    [self kTrimToCount:count];
}

#pragma mark - Private
#pragma mark - Helper Method

- (void)removeAllData
{
    [list removeAllNode];
    if (CFDictionaryGetCount(dict) > 0) {
        CFMutableDictionaryRef holder = dict;
        dict = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        if (_releaseAsynchronously) {
            dispatch_queue_t queue = _releaseOnMainThread ?
            dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            dispatch_async(queue, ^{
                CFRelease(holder);
            });
        } else if (_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRelease(holder);
            });
        } else {
            CFRelease(holder);
        }
    }
}


#pragma mark Notification Handler

- (void)didReceiveMemoryWarningNotification:(NSNotification *)notification
{
    if (self.didReceiveMemoryWarningBlock) {
        self.didReceiveMemoryWarningBlock(self);
    }
    if (_shouldRemoveAllObjectsWhenMemoryWarning) {
        [self removeAllObjects];
    }
}

- (void)didEnterBackgroundNotification:(NSNotification *)notification
{
    if (self.didEnterBackgroundBlock) {
        self.didEnterBackgroundBlock(self);
    }
    if (_shouldRemoveAllObjectsWhenEnteringBackground) {
        [self removeAllObjects];
    }
}


#pragma mark Memory Trim

- (void)autoTrim
{
    __weak typeof (&*self) weakSelf = self;
    if (!autoTrimSwitch) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof (&*weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf trimInBackground];
        [strongSelf autoTrim];
    });
}

- (void)trimInBackground
{
    dispatch_async(trimQueue, ^{
        [self kTrimToCount:self.countLimit];
        [self kExpireClean];
    });
}

- (void)kTrimToCount:(NSUInteger)countLimit
{
    BOOL finish = NO;
    pthread_mutex_lock(&mutexLock);
    if (0 == countLimit) {
        [self removeAllData];
        finish = YES;
    } else if (list->totalCount <= countLimit) {
        finish = YES;
    }
    pthread_mutex_unlock(&mutexLock);
    if (finish) return;
    
    CFMutableArrayRef holder = CFArrayCreateMutable(CFAllocatorGetDefault(), 2, &kCFTypeArrayCallBacks);
    do {
        pthread_mutex_lock(&mutexLock);
        CacheKVNode *node = [list removeTailNode];
        if (node) {
            CFArrayAppendValue(holder, (__bridge const void *)node);
            CFDictionaryRemoveValue(dict, (__bridge const void *)(node->key));
        }
        if (list->totalCount <= countLimit) finish = YES;
        pthread_mutex_unlock(&mutexLock);
    } while (!finish);
    
    if (CFArrayGetCount(holder) > 0) {
        dispatch_queue_t queue = _releaseOnMainThread ?
        dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(queue, ^{
            CFRelease(holder);
        });
    }
}

- (void)kExpireClean
{
    if (!_enableExpireClean) return;
    CFMutableArrayRef holder = CFArrayCreateMutable(CFAllocatorGetDefault(), 2, &kCFTypeArrayCallBacks);
    pthread_mutex_lock(&mutexLock);
    CFTimeInterval now = CACurrentMediaTime();
    CacheKVNode *node = list->head;
    while (node) {
        if (node->expireDate > 0 && now > node->expireDate) {
            [list removeNode:node];
            CFArrayAppendValue(holder, (__bridge const void *)node);
            CFDictionaryRemoveValue(dict, (__bridge const void *)(node->key));
        }
        node = node->next;
    }
    pthread_mutex_unlock(&mutexLock);
    
    if (CFArrayGetCount(holder) > 0) {
        dispatch_queue_t queue = _releaseOnMainThread ?
        dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(queue, ^{
            CFRelease(holder);
        });
    }
}

#pragma mark Setter & Getter

- (NSUInteger)totalCount
{
    pthread_mutex_lock(&mutexLock);
    NSInteger result = list->totalCount;
    pthread_mutex_unlock(&mutexLock);
    return result;
}

- (void)setAutoTrimInterval:(NSTimeInterval)autoTrimInterval
{
    pthread_mutex_lock(&mutexLock);
    _autoTrimInterval = autoTrimInterval;
    if (0 == _autoTrimInterval) {
        autoTrimSwitch = NO;
    } else if (!autoTrimSwitch) {
        autoTrimSwitch = YES;
        [self autoTrim];
    }
    pthread_mutex_unlock(&mutexLock);
}

- (NSTimeInterval)autoTrimInterval
{
    pthread_mutex_lock(&mutexLock);
    NSTimeInterval result = _autoTrimInterval;
    pthread_mutex_unlock(&mutexLock);
    return result;
}

- (void)setReleaseOnMainThread:(BOOL)releaseOnMainThread
{
    pthread_mutex_lock(&mutexLock);
    _releaseOnMainThread = releaseOnMainThread;
    pthread_mutex_unlock(&mutexLock);
}

- (BOOL)releaseOnMainThread
{
    pthread_mutex_lock(&mutexLock);
    BOOL result = _releaseOnMainThread;
    pthread_mutex_unlock(&mutexLock);
    return result;
}

- (void)setReleaseAsynchronously:(BOOL)releaseAsynchronously
{
    pthread_mutex_lock(&mutexLock);
    _releaseAsynchronously = releaseAsynchronously;
    pthread_mutex_unlock(&mutexLock);
}

- (BOOL)releaseAsynchronously
{
    pthread_mutex_lock(&mutexLock);
    BOOL result = _releaseAsynchronously;
    pthread_mutex_unlock(&mutexLock);
    return result;
}

- (NSString *)description
{
    if (_name) {
        return [NSString stringWithFormat:@"<%@: %p> [name: %@]", [self class], self, _name];
    } else {
        return [NSString stringWithFormat:@"<%@: %p>", [self class], self];
    }
}

@end
