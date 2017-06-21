//
//  ZZDBModel.m
//  ZZModel
//
//  Created by 刘家强 on 2017/6/21.
//  Copyright © 2017年 刘家强. All rights reserved.
//

#import "ZZDBModel.h"
#import <objc/runtime.h>

@implementation ZZDBModel

- (NSInteger)e_creat_time {
    if (_e_creat_time == 0) {
        return [[NSDate date] timeIntervalSince1970];
    }
    return _e_creat_time;
}

- (NSInteger)e_creat_version {
    if (_e_creat_version == 0) {
        return [ZZDBCommon shared].vision;
    }
    return _e_creat_version;
}

+ (NSArray *)findWithSql:(NSString *)sql {
    ZZDBCommon *zzDB = [ZZDBCommon shared];
    NSMutableArray *users = [NSMutableArray array];
    [zzDB.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            ZZDBModel *model = [[self.class alloc] init];
            for (int i=0; i< model.e_names.count; i++) {
                NSString *columeName = [model.e_names objectAtIndex:i];
                NSString *columeType = [model.e_types objectAtIndex:i];
                if ([columeType isEqualToString:SqlText]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else if ([columeType isEqualToString:SqlInteger]) {
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                } else {
                    [model setValue:[NSNumber numberWithDouble:[resultSet doubleForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
    }];
    
    return users;
}

/** 删除单个对象 */
- (BOOL)deleteObject {
    ZZDBCommon *zzDB = [ZZDBCommon shared];
    __block BOOL res = NO;
    [zzDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:e_id];
        if (!primaryValue || primaryValue <= 0) {
            return;
        }
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName, e_id];
        res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

- (BOOL)deleteWithSql:(NSString *)sql {
    ZZDBCommon *zzDB = [ZZDBCommon shared];
    __block BOOL res = NO;
    [zzDB.dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:sql];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;

}

- (BOOL)saveOrUpdate {
    
    self.e_update_time = [[NSDate date] timeIntervalSince1970];
    self.e_update_version = [ZZDBCommon shared].vision;
    
    id primaryValue = [self valueForKey:e_id];
    if ([primaryValue intValue] <= 0) {
        return [self save];
    }
    
    return [self update];
}

- (BOOL)save {
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    for (int i = 0; i < self.e_names.count; i++) {
        NSString *proname = [self.e_names objectAtIndex:i];
        if ([proname isEqualToString:e_id]) {
            continue;
        }
        [keyString appendFormat:@"%@,", proname];
        [valueString appendString:@"?,"];
        id value = [self valueForKey:proname];
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    ZZDBCommon *zzDB = [ZZDBCommon shared];
    __block BOOL res = NO;
    [zzDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
        res = [db executeUpdate:sql withArgumentsInArray:insertValues];
        self.e_id = res?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
        NSLog(res?@"插入成功":@"插入失败");
    }];
    return res;
}

/** 更新单个对象 */
- (BOOL)update {
    ZZDBCommon *zzDB = [ZZDBCommon shared];
    __block BOOL res = NO;
    [zzDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:e_id];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray  array];
        for (int i = 0; i < self.e_names.count; i++) {
            NSString *proname = [self.e_names objectAtIndex:i];
            if ([proname isEqualToString:e_id]) {
                continue;
            }
            [keyString appendFormat:@" %@=?,", proname];
            id value = [self valueForKey:proname];
            if (!value) {
                value = @"";
            }
            [updateValues addObject:value];
        }
        
        //删除最后那个逗号
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName, keyString, e_id];
        [updateValues addObject:primaryValue];
        res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        NSLog(res?@"更新成功":@"更新失败");
    }];
    return res;
}



// 第一次调用的时候
+ (void)initialize {
    if (self != [ZZDBModel class]) {
        [self createTable];
    }
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *dic = [self.class getAllProperties];
        _e_names = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"name"]];
        _e_types = [[NSMutableArray alloc] initWithArray:[dic objectForKey:@"type"]];
    }
    
    return self;
}
/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable {
    __block BOOL res = YES;
    ZZDBCommon *zzDB = [ZZDBCommon shared];
    [zzDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *columeAndType = [self.class getColumeAndTypeString];
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
        if (![db executeUpdate:sql]) {
            res = NO;
            *rollback = YES;
            return;
        };
        
        NSMutableArray *columns = [NSMutableArray array];
        FMResultSet *resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
        NSDictionary *dict = [self.class getAllProperties];
        NSArray *properties = [dict objectForKey:@"name"];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
        //过滤数组
        NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
        for (NSString *column in resultArray) {
            NSUInteger index = [properties indexOfObject:column];
            NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
            NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@",NSStringFromClass(self.class), fieldSql , @"''"];
            if (![db executeUpdate:sql]) {
                res = NO;
                *rollback = YES;
                return ;
            }
        }
    }];
    
    return res;
}

/** 清空表 */
+ (BOOL)clearTable {
    ZZDBCommon *zzDB = [ZZDBCommon shared];
    __block BOOL res = YES;
    [zzDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res?@"清空成功":@"清空失败");
    }];
    return res;
}

+ (NSString *)getColumeAndTypeString {
    NSMutableString* pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i=0; i< proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}

/** 获取所有属性，包含主键pk */
+ (NSDictionary *)getAllProperties {
    NSDictionary *dict = [self.class getPropertys];
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    [proNames addObject:e_id];
    [proNames addObject:e_creat_time];
    [proNames addObject:e_creat_version];
    [proNames addObject:e_update_time];
    [proNames addObject:e_update_version];
    [proTypes addObject:[NSString stringWithFormat:@"%@ %@", SqlInteger, @"primary key"]];
    [proTypes addObject:SqlInteger];
    [proTypes addObject:SqlInteger];
    [proTypes addObject:SqlInteger];
    [proTypes addObject:SqlInteger];
    [proNames addObjectsFromArray:[dict objectForKey:@"names"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"types"]];
    
    return @{
             @"name" : proNames,
             @"type" : proTypes
             };
}

/**
 *  获取该类的所有属性
 */
+ (NSDictionary *)getPropertys {
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (int i = 0; i < outCount; i++) {
        
        objc_property_t property = properties[i];
        //获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        [proNames addObject:propertyName];
        //获取属性类型等参数
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        if ([propertyType hasPrefix:@"T@"]) {
            [proTypes addObject:SqlText];
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]||[propertyType hasPrefix:@"Tq"]||[propertyType hasPrefix:@"TQ"]) {
            [proTypes addObject:SqlInteger];
        } else {
            [proTypes addObject:SqlReal];
        }
        
    }
    free(properties);
    return @{
             @"names" : proNames,
             @"types" : proTypes
             };
}



@end
