//
//  PDStorage.m
//  PDStorage
//
//  Created by liang on 2018/7/12.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "PDStorage.h"
#import "PDStoragePool.h"

@interface PDStorage () {
    NSString *_databasePath;
    PDQueryDriver *_driver;
}

@end

@implementation PDStorage

- (void)dealloc {
    [_driver close];
    _driver = nil;
}

- (instancetype)initWithDatabasePath:(NSString *)databasePath {
    if (!databasePath) return nil;
    
    // Lazy load.
    PDStoragePool *pool = [PDStoragePool sharedPool];
    PDStorage *storage = [pool valueForKey:databasePath];
    if (storage) return storage;
    
    self = [super init];
    if (self) {
        _databasePath = [databasePath copy];
        _driver = [[PDQueryDriver alloc] initWithDatabasePath:_databasePath];
        [_driver open];
    }
    
    // Store storage to pool.
    [pool setValue:self forKey:databasePath];
    return self;
}

- (PDQueryItem *)createTable:(NSString *)table columns:(NSString *)columns {
    NSString *stmt = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@);", table, columns];
    return [_driver query:stmt];
}

- (PDQueryItem *)dropTable:(NSString *)table {
    NSString *stmt = [NSString stringWithFormat:@"DROP TABLE %@;", table];
    return [_driver query:stmt];
}

- (PDQueryItem *)execute:(NSString *)stmt bind:(NSArray *)bind {
    return [_driver query:stmt bind:bind];
}

- (PDQueryItem *)insert:(NSDictionary *)keyValueDict into:(NSString *)table {
    NSArray *keys = [keyValueDict allKeys];
    NSMutableArray *bind = [[NSMutableArray alloc] init];
    
    NSString *fields = @"";
    NSString *values = @"";
    
    for (NSString *key in keys) {
        fields = [fields stringByAppendingString:key];
        fields = [fields stringByAppendingString:@","];
        values = [values stringByAppendingString:@"?,"];
        
        [bind addObject:[keyValueDict objectForKey:key]];
    }
    
    if (keys.count > 0) {
        fields = [fields substringToIndex:[fields length] - 1];
        values = [values substringToIndex:[values length] - 1];
    }
    NSString *stmt = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@);", table, fields, values];
    return [_driver query:stmt bind:bind];
}

- (PDQueryItem *)deleteByCondition:(NSString *)condition from:(NSString *)table {
    NSString *stmt = [NSString stringWithFormat:@"DELETE FROM %@", table];
    
    if (condition.length > 0) {
        stmt = [stmt stringByAppendingFormat:@" WHERE %@", condition];
    }
    stmt = [stmt stringByAppendingString:@";"];
    return [_driver query:stmt];
}

- (PDQueryItem *)updateByCondition:(NSString *)condition bind:(NSDictionary *)keyValueDict from:(NSString *)table {
    NSString *bindStmt = @"";
    
    for (NSString *key in keyValueDict.allKeys) {
        bindStmt = [bindStmt stringByAppendingString:[NSString stringWithFormat:@"%@=%@,", key, [keyValueDict objectForKey:key]]];
    }
    
    if (keyValueDict.allKeys.count > 0) {
        bindStmt = [bindStmt substringToIndex:bindStmt.length - 1];
    }
    
    NSString *stmt = [NSString stringWithFormat:@"UPDATE %@ SET %@", table, bindStmt];
    
    if (condition.length) {
        stmt = [stmt stringByAppendingString:[NSString stringWithFormat:@"WHERE %@", condition]];
    }
    stmt = [stmt stringByAppendingString:@";"];
    return [_driver query:stmt];
}

- (PDQueryItem *)select:(NSString *)columns byCondition:(NSString *)condition from:(NSString *)table {
    NSString *stmt = [NSString stringWithFormat:@"SELECT %@ FROM %@", columns, table];
    if (condition.length > 0) {
        stmt = [stmt stringByAppendingString:[NSString stringWithFormat:@"WHERE %@", condition]];
    }
    stmt = [stmt stringByAppendingString:@";"];
    return [_driver query:stmt];
}

@end
