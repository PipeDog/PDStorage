//
//  PDStoragePool.m
//  PDStorage
//
//  Created by liang on 2018/7/13.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "PDStoragePool.h"
#import "PDStorage.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@interface PDStoragePool () {
    NSMutableDictionary<NSString *, PDStorage *> *_pool;
    dispatch_semaphore_t _lock;
}

@end

@implementation PDStoragePool

static PDStoragePool *__sharedPool = nil;

+ (PDStoragePool *)sharedPool {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__sharedPool == nil) {
            __sharedPool = [[self alloc] init];
        }
    });
    return __sharedPool;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__sharedPool == nil) {
            __sharedPool = [super allocWithZone:zone];
        }
    });
    return __sharedPool;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pool = [NSMutableDictionary dictionary];
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (id)valueForKey:(NSString *)key {
    if (!key) return nil;
    
    return [_pool valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if (!key) return;
    if (!value || ![value isKindOfClass:[PDStorage class]]) return;
    
    Lock();
    [_pool setValue:value forKey:key];
    Unlock();
}

@end
