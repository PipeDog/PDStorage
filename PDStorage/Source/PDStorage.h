//
//  PDStorage.h
//  PDStorage
//
//  Created by liang on 2018/7/12.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PDQueryDriver.h"

@interface PDStorage : NSObject

@property (nonatomic, copy, readonly) NSString *databasePath;

- (instancetype)initWithDatabasePath:(NSString *)databasePath;

- (PDQueryItem *)createTable:(NSString *)table columns:(NSString *)columns;
- (PDQueryItem *)dropTable:(NSString *)table;

- (PDQueryItem *)execute:(NSString *)stmt bind:(NSArray *)bind;

- (PDQueryItem *)insert:(NSDictionary *)keyValueDict into:(NSString *)table;
- (PDQueryItem *)deleteByCondition:(NSString *)condition from:(NSString *)table;
- (PDQueryItem *)updateByCondition:(NSString *)condition bind:(NSDictionary *)keyValueDict from:(NSString *)table;
- (PDQueryItem *)select:(NSString *)columns byCondition:(NSString *)condition from:(NSString *)table;

@end
