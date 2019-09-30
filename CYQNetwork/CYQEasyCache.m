//
//  CYQEasyCache.m
//  cyqnetworktool
//
//  Created by cyq on 2019/9/22.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQEasyCache.h"
#import <CommonCrypto/CommonDigest.h>
#import <sqlite3.h>

static sqlite3 * _sqlliteDb = nil;

@implementation CYQEasyCache

+(void)removeCacheWithCacheId:(NSString *)cacheId{
    NSString *cacheIdMd5 = [self md5_32bit:cacheId];
    if (![self openDb]) {
        return;
    }
    NSArray *data = [self findCacheItemById:cacheIdMd5];
    if (data && data.count > 0) {
        NSString *resumeDataPath = [[data objectAtIndex:0] objectForKey:@"resumeDataPath"];
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:resumeDataPath]) {
            [manager removeItemAtPath:resumeDataPath error:nil];
        }
        [self deleteCacheItemById:cacheId];
    }
    [self closeDB];
}

+(void)saveCacheWithCacheId:(NSString *)cacheId resumeData:(NSData *)resumeData{
    NSString *cacheIdMd5 = [self md5_32bit:cacheId];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *docuDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory
                                                             , NSUserDomainMask
                                                             , YES) firstObject];
    NSString *resumeDataPath = [[docuDir stringByAppendingPathComponent:cacheIdMd5] stringByAppendingPathExtension:@"resume"];

    if ([manager fileExistsAtPath:resumeDataPath]) {
        [manager removeItemAtPath:resumeDataPath error:nil];
    }
    
    [resumeData writeToFile:resumeDataPath atomically:YES];
    if (![self openDb]) {
        return;
    }
    NSArray *data = [self findCacheItemById:cacheIdMd5];
    if (data && data.count > 0) {
        [self updateCacheItemWithId:cacheIdMd5 resumeDataPath:resumeDataPath];
    }else{
        [self addCacheItemWithId:cacheIdMd5 resumeDataPath:resumeDataPath];
    }
    [self closeDB];
}

+(NSData *)getResumeDataWithCacheId:(NSString *)cacheId{
    if (![self openDb]) {
        return nil;
    }
    NSArray *data = [self findCacheItemById:[self md5_32bit:cacheId]];
    [self closeDB];
    if (!data || data.count == 0) {
        return nil;
    }
    return [NSData dataWithContentsOfFile:[[data objectAtIndex:0] objectForKey:@"resumeDataPath"]];
}

+(NSString *)md5_32bit:(NSString *)input {
    const char * str = [input UTF8String];
    unsigned char md[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (int)strlen(str), md);
    NSMutableString * ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02X",md[i]];
    }
    return ret;
}

+(BOOL)addCacheItemWithId:(NSString*)cacheIdMd5 resumeDataPath:(NSString*)resumeDataPath{
    NSString *sql = [NSString stringWithFormat:@"insert into cyq_cache(cacheId,resumeDataPath) values ('%@','%@') ",cacheIdMd5,resumeDataPath];
    return [self execSql:sql];
}

+(BOOL)updateCacheItemWithId:(NSString*)cacheIdMd5 resumeDataPath:(NSString*)resumeDataPath{
    NSString *sql = [NSString stringWithFormat:@"update cyq_cache set resumeDataPath = '%@' where cacheId = '%@'",resumeDataPath,cacheIdMd5];
    return [self execSql:sql];
}

+(BOOL)deleteCacheItemById:(NSString*)cacheIdMd5{
    NSString *sql = [NSString stringWithFormat:@"delete from cyq_cache where cacheId = '%@'",cacheIdMd5];
    return [self execSql:sql];
}

+(NSArray <NSDictionary *>*)findCacheItemById:(NSString*)cacheIdMd5{
    NSString *sql = [NSString stringWithFormat:@"select cacheId,resumeDataPath from cyq_cache where cacheId = '%@'",cacheIdMd5];
    return [self querySql:sql];
}

+(BOOL)execSql:(NSString*)sql{
    char *errmsg = NULL;
    int result = sqlite3_exec(_sqlliteDb, [sql UTF8String], NULL, NULL, &errmsg);
    printf("%s\n",errmsg);
    if (result == SQLITE_OK) {
        return YES;
    } else {
        return NO;
    }
}

+(NSArray <NSDictionary *>*)querySql:(NSString *)sql{
    
    sqlite3_stmt *ppStmt = nil;
    if (sqlite3_prepare_v2(_sqlliteDb, sql.UTF8String, -1, &ppStmt, nil) != SQLITE_OK) {
        return nil;
    }
    NSMutableArray *rowDicArray = [NSMutableArray array];
    while (sqlite3_step(ppStmt) == SQLITE_ROW) {
        NSMutableDictionary *rowDictionary = [NSMutableDictionary dictionary];
        int columnCount = sqlite3_column_count(ppStmt);
        for (int i=0; i<columnCount; i++) {
            const char *columnNameC = sqlite3_column_name(ppStmt, i);
            NSString *columnName = [NSString stringWithUTF8String:columnNameC];
            int type = sqlite3_column_type(ppStmt, i);
            id value = nil;
            switch (type) {
                case SQLITE_INTEGER:
                    value = @(sqlite3_column_int(ppStmt,i));
                    break;
                case SQLITE_FLOAT:
                    value = @(sqlite3_column_double(ppStmt, i));
                    break;
                case SQLITE3_TEXT:
                    value = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(ppStmt, i)];
                    break;
                case SQLITE_BLOB:
                    value = CFBridgingRelease(sqlite3_column_blob(ppStmt, i));
                    break;
                case SQLITE_NULL:
                    value = @"";
                    break;
            }
            [rowDictionary setValue:value forKey:columnName];
        }
        [rowDicArray addObject:rowDictionary];
    }
    sqlite3_finalize(ppStmt);
    return rowDicArray;
}

+(BOOL)createTable{
    NSString *sql = @"CREATE TABLE IF NOT EXISTS cyq_cache (id INT,cacheId VARCHAR(64),resumeDataPath VARCHAR(512))";
    int result = sqlite3_exec(_sqlliteDb, [sql UTF8String], NULL, NULL, NULL);
    if (result == SQLITE_OK) {
        return YES;
    } else {
        return NO;
    }
}

+(BOOL)openDb{
    NSString* dbPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory
                                                            , NSUserDomainMask
                                                            , YES) firstObject];
    dbPath = [dbPath stringByAppendingPathComponent:@"cyeasydb.sqllite"];
    if (sqlite3_open(dbPath.UTF8String, &_sqlliteDb) == SQLITE_OK) {
        return YES;
    }
    return NO;
}

+(void)closeDB{
    sqlite3_close(_sqlliteDb);
}

+(void)initialize{
    if ([self openDb]) {
        [self createTable];
    }
    [self closeDB];
}
@end
