//
//  PDQueryDriver.m
//  PDStorage
//
//  Created by liang on 2018/7/12.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import "PDQueryDriver.h"
#import <sqlite3.h>

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@interface PDQueryDriver () {
    NSString *_databasePath;
    sqlite3 *_db;
    dispatch_semaphore_t _lock;
}

@end

@implementation PDQueryDriver

- (instancetype)initWithDatabasePath:(NSString *)databasePath {
    self = [super init];
    if (self) {
        _databasePath = databasePath;
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (BOOL)open {
    NSAssert(_databasePath.length != 0, @"Param _databasePath can not be nil!");
    Lock();
    int ro = sqlite3_open([_databasePath UTF8String], &_db);
    Unlock();
    
    if (ro == SQLITE_OK) {
        return YES;
    }
    return NO;
}

- (BOOL)close {
    NSAssert(_db != nil, @"Param _db can not be nil!");
    Lock();
    int rc = sqlite3_close(_db);
    Unlock();
    
    if (rc == SQLITE_OK) {
        return YES;
    }
    return NO;
}

- (PDQueryItem *)query:(NSString *)stmt {
    return [self query:stmt bind:nil];
}

- (PDQueryItem *)query:(NSString *)stmt bind:(NSArray *)bind {
    NSAssert(stmt.length == 0, @"Param stmt can not be nil!");
    Lock();
    PDQueryItem *queryItem = [[PDQueryItem alloc] init];
    sqlite3_stmt *sqlStmt;
    
    queryItem.code = sqlite3_prepare_v2(_db, [stmt UTF8String], -1, &sqlStmt, NULL);
    
    if (queryItem != SQLITE_OK) {
        sqlite3_finalize(sqlStmt);
        Unlock();
        queryItem.msg = [[NSString alloc] initWithUTF8String:sqlite3_errmsg(_db)];
        return queryItem;
    }
    
    // Insert or update sql data.
    NSArray *values = [bind copy];
    
    if (values.count > 0) {
        for (int i = 0; i < values.count; i ++) {
            int index = i + 1;
            id value = values[i];
            int rb = -1;
            
            if ([value isKindOfClass:[NSString class]]) {
                rb = sqlite3_bind_text(sqlStmt, index, [value UTF8String], -1, SQLITE_TRANSIENT);
            } else if ([value isKindOfClass:[NSData class]]) {
                rb = sqlite3_bind_blob(sqlStmt, index, ((NSData *)value).bytes, -1, SQLITE_TRANSIENT);
            } else if ([value isKindOfClass:[NSNumber class]]) {
                const char *objcType = [(NSNumber *)value objCType];

#define PD_OBJCTYPE_ARGS_NUM(_type_) (strcmp(objcType, @encode(_type_)) == 0)
                
                if (PD_OBJCTYPE_ARGS_NUM(int) ||
                    PD_OBJCTYPE_ARGS_NUM(short) ||
                    PD_OBJCTYPE_ARGS_NUM(long) ||
                    PD_OBJCTYPE_ARGS_NUM(long long) ||
                    PD_OBJCTYPE_ARGS_NUM(unsigned int) ||
                    PD_OBJCTYPE_ARGS_NUM(unsigned short) ||
                    PD_OBJCTYPE_ARGS_NUM(unsigned long) ||
                    PD_OBJCTYPE_ARGS_NUM(unsigned long long)) {
                    
                    rb = sqlite3_bind_int64(sqlStmt, index, (sqlite3_int64)[value longLongValue]);
                } else if (PD_OBJCTYPE_ARGS_NUM(float) ||
                           PD_OBJCTYPE_ARGS_NUM(double)) {
                    
                    rb = sqlite3_bind_double(sqlStmt, index, [value doubleValue]);
                } else if (PD_OBJCTYPE_ARGS_NUM(bool)) {
                    
                    rb = sqlite3_bind_int(sqlStmt, index, [value boolValue]);
                }
                    
#undef PD_OBJCTYPE_ARGS_NUM

            } else { }
            
            NSAssert(rb != SQLITE_OK, @"Sql stmt execute error!");
        }
    }
    
    // Query data.
    NSMutableArray<NSDictionary *> *rows = [NSMutableArray array];
    
    while (sqlite3_step(sqlStmt) == SQLITE_ROW) {
        
        NSMutableDictionary *row = [NSMutableDictionary dictionary];
        int columnsCount = sqlite3_column_count(sqlStmt);
        
        for (int i = 0; i < columnsCount; i ++) {
            int type = sqlite3_column_type(sqlStmt, i);
            NSString *name = [[NSString alloc] initWithUTF8String:sqlite3_column_name(sqlStmt, i)];
            
            switch (type) {
                case SQLITE_INTEGER: {
                    sqlite3_int64 value = sqlite3_column_int64(sqlStmt, i);
                    [row setValue:@(value) forKey:name];
                } break;
                case SQLITE_FLOAT: {
                    double value = sqlite3_column_double(sqlStmt, i);
                    [row setValue:@(value) forKey:name];
                } break;
                case SQLITE_TEXT: {
                    const unsigned char *text = sqlite3_column_text(sqlStmt, i);
                    if (text != NULL) {
                        NSString *value = [NSString stringWithCString:(const char *)text encoding:NSUTF8StringEncoding];
                        [row setValue:value forKey:name];
                    }
                } break;
                case SQLITE_BLOB: {
                    int len = sqlite3_column_bytes(sqlStmt, i);
                    const void *blob = sqlite3_column_blob(sqlStmt, i);
                    if (blob != NULL) {
                        NSData *value = [NSData dataWithBytes:blob length:len];
                        [row setValue:value forKey:name];
                    }
                } break;
                default: break;
            }
        }
        [rows addObject:[row copy]];
    }
    
    sqlite3_finalize(sqlStmt);
    Unlock();
    queryItem.rows = [rows copy];
    return queryItem;
}

@end
