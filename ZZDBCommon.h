//
//  ZZDBCommon.h
//  ZZModel
//
//  Created by 刘家强 on 2017/6/21.
//  Copyright © 2017年 刘家强. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FMDB/FMDB.h>

@interface ZZDBCommon : NSObject

@property (nonatomic, strong, readonly) FMDatabaseQueue *dbQueue;
@property (nonatomic, assign, readonly) NSInteger vision;

+ (instancetype)shared;

@end
