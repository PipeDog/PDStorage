//
//  PDQueryDriver.h
//  PDStorage
//
//  Created by liang on 2018/7/12.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDQueryItem.h"

@interface PDQueryDriver : NSObject

- (instancetype)initWithDatabasePath:(NSString *)databasePath;

- (BOOL)open;
- (BOOL)close;

- (PDQueryItem *)query:(NSString *)stmt;
- (PDQueryItem *)query:(NSString *)stmt bind:(NSArray *)bind;

@end
