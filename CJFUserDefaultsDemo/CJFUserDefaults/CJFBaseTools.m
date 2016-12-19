//
//  CJFBaseTools.m
//  iPadDemo
//
//  Created by ChengJianFeng on 16/9/28.
//  Copyright © 2016年 ChengJianFeng. All rights reserved.
//

#import "CJFBaseTools.h"

CJFBaseTools_t CJFBaseTools;

#pragma mark - 类型合法转换

static NSString *CJF_toValidateString(NSString *string) {
    BOOL result = NO;
    if (string && [string isKindOfClass:[NSString class]] && [string length]) {
        result = YES;
    }
    return result ? string : @"";
}

static NSArray *CJF_toValidateArray(NSArray *array) {
    BOOL result = NO;
    if (array && [array isKindOfClass:[NSArray class]] && [array count]) {
        result = YES;
    }
    return result ? array : @[];
}

static NSNumber *CJF_toValidateNumber(NSNumber *number) {
    BOOL result = NO;
    if (number && [number isKindOfClass:[NSNumber class]]) {
        result = YES;
    }
    
    return result ? number : @0;
}

static NSDictionary *CJF_toValidateDictionary(NSDictionary *dictionary) {
    BOOL result = NO;
    if (dictionary && [dictionary isKindOfClass:[NSDictionary class]]) {
        result = YES;
    }
    return result ? dictionary : @{};
}

#pragma mark - 类型值合法性判断，注意会额外判断值的合法性

static BOOL CJF_validateString(NSString *string) {
    BOOL result = NO;
    if (string && [string isKindOfClass:[NSString class]] && [string length]) {
        result = YES;
    }
    return result;
}

static BOOL CJF_validateArray(NSArray *array) {
    BOOL result = NO;
    if (array && [array isKindOfClass:[NSArray class]] && [array count]) {
        result = YES;
    }
    return result;
}

static BOOL CJF_validateNumber(NSNumber *number) {
    BOOL result = NO;
    if (number && [number isKindOfClass:[NSNumber class]]) {
        result = YES;
    }
    return result;
}

static BOOL CJF_validateDictionary(NSDictionary *dictionary) {
    BOOL result = NO;
    if (dictionary && [dictionary isKindOfClass:[NSDictionary class]]) {
        result = YES;
    }
    return result;
}

// NSData, NSString, NSNumber, NSDate, NSArray, or NSDictionary.
static BOOL CJF_validatePropetyList(id value)
{
    BOOL result = YES;
    if( [value isKindOfClass:[NSData class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSDate class]] ){
        result = YES;
    }else if ( [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]){
        if( [value isKindOfClass:[NSDictionary class]] ){
            value = [(NSDictionary*)value allValues];
            NSArray* keys = [value allKeys];
            for (id key in keys) {
                if( ![key isKindOfClass:[NSString class]] ){
                    return NO;
                }
            }
        }
        
        for (id element in value) {
            if( !CJF_validatePropetyList(element) ){
                result = NO;
                return NO;
            }
        }
    }else{
        result = NO;
    }
    return result;
}

#pragma mark - 文件相关操作

static NSString *CJF_getFilePath(NSString* filename) {
    if( !CJF_validateString(filename) ){
        return nil;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *pathToUserCopyOfPlist = [documentsDirectory stringByAppendingPathComponent:filename];
    return pathToUserCopyOfPlist;
}

static NSString *CJF_getFilePathWithExt(NSString* filename, NSString* ext) {
    if( !CJF_validateString(filename) ){
        return nil;
    }
    if( !CJF_validateString(ext) ){
        return CJF_getFilePath(filename);
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *pathToUserCopyOfPlist = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", filename, ext]];
    return pathToUserCopyOfPlist;
}

BOOL CJF_creatDirInDocument(NSString *dirName)
{
    if( !CJF_validateString(dirName) ){
        return @"";
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pathDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *createDir = [pathDocuments stringByAppendingPathComponent:dirName];
    
    // 判断文件夹是否存在，如果不存在，则创建
    if (![fileManager fileExistsAtPath:createDir]) {
        NSError* error = nil;
        BOOL suc = [fileManager createDirectoryAtPath:createDir withIntermediateDirectories:YES attributes:nil error:&error];
        if( suc && (error == nil) ){
            return YES;
        }else{
            return NO;
        }
    } else {
        return NO;
    }
}


static NSString *CJF_getBundleFilePath(NSString* filename, NSString* ext) {
    return [[NSBundle mainBundle] pathForResource:filename ofType:ext];
}


__attribute__((constructor)) static void KSCrashInjection(void) {
    CJFBaseTools.toValidateString = CJF_toValidateString;
    CJFBaseTools.toValidateArray = CJF_toValidateArray;
    CJFBaseTools.toValidateNumber = CJF_toValidateNumber;
    CJFBaseTools.toValidateDictionary = CJF_toValidateDictionary;
    
    CJFBaseTools.validateString = CJF_validateString;
    CJFBaseTools.validateArray = CJF_validateArray;
    CJFBaseTools.validateNumber = CJF_validateNumber;
    CJFBaseTools.validateDictionary = CJF_validateDictionary;
    CJFBaseTools.validatePropetyList = CJF_validatePropetyList;
    
    CJFBaseTools.getFilePath = CJF_getFilePath;
    CJFBaseTools.getFilePathWithExt = CJF_getFilePathWithExt;
    CJFBaseTools.getBundleFilePath = CJF_getBundleFilePath;
    CJFBaseTools.creatDirInDocument = CJF_creatDirInDocument;
    
}
