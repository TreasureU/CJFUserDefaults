//
//  CJFBaseTools.h
//  iPadDemo
//
//  Created by ChengJianFeng on 16/9/28.
//  Copyright © 2016年 ChengJianFeng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _CJFBaseTools_t{
    //获取合法类型值，只适用于初始化
    NSString* (*toValidateString)(NSString *string);
    NSArray* (*toValidateArray)(NSArray *array);
    NSNumber* (*toValidateNumber)(NSNumber *number);
    NSDictionary* (*toValidateDictionary)(NSDictionary *dictionary);
    
    //类型值合法性判断，注意会额外判断值的合法性
    BOOL (*validateString)(NSString *string);
    BOOL (*validateArray)(NSArray *array);
    BOOL (*validateNumber)(NSNumber *number);
    BOOL (*validateDictionary)(NSDictionary *dictionary);
    BOOL (*validatePropetyList)(id value);
    
    //文件路径辅助
    NSString* (*getFilePath)(NSString *filename);
    NSString* (*getFilePathWithExt)(NSString* filename, NSString* ext);
    NSString* (*getBundleFilePath)(NSString* filename, NSString* ext);
    
    //创建文件夹,支持多级文件夹创建
    BOOL (*creatDirInDocument)(NSString *dirName);
    
} CJFBaseTools_t;

/*!
 *  开发常用工具包
 */
extern CJFBaseTools_t CJFBaseTools;

