//
//  ZZDBModel.h
//  ZZModel
//
//  Created by 刘家强 on 2017/6/21.
//  Copyright © 2017年 刘家强. All rights reserved.
//  基于 github:https://github.com/Joker-King/JKDBModel 简化

#import "ZZDBCommon.h"

/**
 NSInteger
 CGFloat
 NSString
 NSData
 */

/** SQLite五种数据类型 */
static NSString *const SqlText = @"text";
static NSString *const SqlInteger = @"integer";
static NSString *const SqlReal = @"real";
static NSString *const SqlBlob = @"blob";
static NSString *const SqlNull = @"null";

static NSString *const e_id = @"e_id";
static NSString *const e_creat_time = @"e_creat_time";
static NSString *const e_update_time = @"e_update_time";
static NSString *const e_creat_version = @"e_creat_version";
static NSString *const e_update_version = @"e_update_version";

@interface ZZDBModel : NSObject

/** 主键 id */
@property (nonatomic, assign) NSInteger e_id;
@property (nonatomic, assign) NSInteger e_creat_time;
@property (nonatomic, assign) NSInteger e_update_time;
@property (nonatomic, assign) NSInteger e_creat_version;
@property (nonatomic, assign) NSInteger e_update_version;

/** 列名 */
@property (retain, readonly, nonatomic) NSMutableArray *e_names;
/** 列类型 */
@property (retain, readonly, nonatomic) NSMutableArray *e_types;

/** 保存或更新
 * 如果不存在主键，保存，
 * 有主键，则更新
 */
- (BOOL)saveOrUpdate;
/** 删除单个数据 */
- (BOOL)deleteObject;
- (BOOL)deleteWithSql:(NSString *)sql;
/** 查询数据 */
+ (NSArray *)findWithSql:(NSString *)sql;
/** 清空表 */
+ (BOOL)clearTable;

@end
