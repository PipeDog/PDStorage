//
//  PDQueryItem.h
//  PDStorage
//
//  Created by liang on 2018/7/12.
//  Copyright © 2018年 PipeDog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDQueryItem : NSObject

@property (nonatomic, assign) int code;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSArray<NSDictionary *> *rows;

@end
