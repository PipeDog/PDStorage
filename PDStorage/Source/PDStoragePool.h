//
//  PDStoragePool.h
//  PDStorage
//
//  Created by liang on 2018/7/13.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDStoragePool : NSObject

@property (class, strong, readonly) PDStoragePool *sharedPool;

- (id)valueForKey:(NSString *)key;

- (void)setValue:(id)value forKey:(NSString *)key;

@end
