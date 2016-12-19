//
//  CJFAssertionHandler.m
//  CJFUserDefaultsDemo
//
//  Created by ChengJianFeng on 2016/12/19.
//  Copyright © 2016年 ChengJianFeng. All rights reserved.
//

#import "CJFAssertionHandler.h"

@implementation CJFAssertionHandler

//处理Objective-C的断言
- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format,...
{
    NSLog(@"NSAssert Failure: Method %@ for object %@ in %@ ,line: %li", NSStringFromSelector(selector), object, fileName, (long)line);
    abort();
}
//处理C的断言
- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format,...
{
    NSLog(@"NSCAssert Failure: Function (%@) in %@ ,line: %li", functionName, fileName, (long)line);
    abort();
}

@end
