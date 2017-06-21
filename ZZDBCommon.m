//
//  ZZDBCommon.m
//  ZZModel
//
//  Created by 刘家强 on 2017/6/21.
//  Copyright © 2017年 刘家强. All rights reserved.
//

#import "ZZDBCommon.h"

@implementation ZZDBCommon

static ZZDBCommon *_instance = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init] ;
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[self.class filePath]];
        
        NSString *visionStr = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"];
        NSArray <NSString *>*visionArr = [visionStr componentsSeparatedByString:@"."];
        switch (visionArr.count) {
            case 3: if (visionArr.count > 2) _vision = [visionArr[2] integerValue];
            case 2: if (visionArr.count > 1) _vision += [visionArr[1] integerValue] * 100;
            case 1: if (visionArr.count > 0) _vision += [visionArr[0] integerValue] * 10000;
        }
    }
    return self;
}

+ (NSString *)filePath {
    NSString *doc = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES)firstObject] stringByAppendingPathComponent:@"ZZDB"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir;
    BOOL exit =[fileManager fileExistsAtPath:doc isDirectory:&isDir];
    if (!exit || !isDir) {
        [fileManager createDirectoryAtPath:doc withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *filePath = [doc stringByAppendingPathComponent:@"zzdb.sqlite"];
    return filePath;
}

@end
