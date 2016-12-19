//
//  CJFUserDefaults.h
//  iPadDemo
//
//  Created by ChengJianFeng on 16/9/28.
//  Copyright © 2016年 ChengJianFeng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 NSUserDefaults的替代品，所有接口都是线程安全的
 每1分钟自动保存一次，在程序进入后台以及退出前会自动保存一次
 支持手动调用持久化接口：同步持久化 和 异步持久化
 其他接口完全仿照NSUserDefaults，力争将大家的改动范围降低到最小
 */
@interface CJFUserDefaults : NSObject

+(instancetype) alloc __attribute__((unavailable("alloc not available, call sharedInstance instead")));
-(instancetype) init __attribute__((unavailable("init not available, call sharedInstance instead")));
+(instancetype) new __attribute__((unavailable("new not available, call sharedInstance instead")));

/**
 Warning: dispatch_once is not reentrant
 Don't make a recursive call to sharedInstance from inside the dispatch_once block.
 */
+( CJFUserDefaults * )standardUserDefaults;

/**
 应尽量避免调用，消耗极大
 重置manager内的所有数据，取消所有写入操作，并在queue操作完全结束后，将持久化文件删除
 可以确保manager内数据是空的，持久化文件删除失败的情况很少，全由系统情况引起
 */
-(void)resetStandardUserDefaults;

//----------------------------基础通用操作----------------------------


/**
 获取指定key值的对象

 @param key key值，当不为NSString时，将返回nil

 @return key值存在则返回对象，否则返回nil
 */
-(nullable id)objectForKey:(NSString *)key;


/**
 设置特定key值的value
 如果key值不合法则返回nil，否则 value存在则写入，value=nil则移除相应的key值和value。
 写入时将做PropetyList递归校验
 如果value不在 (instances of NSData, NSDate, NSNumber, NSString, NSArray, or NSDictionary) 中，则赋值失败
 写入NSURL对象将被archive为NSData存储，取出时建议使用 URLForKey：，否则需要自己将NSData unachive 为NSURL。
 
 @param value value对象
 @param key   key值对象

 @return key不合法则返回NO，value为nil则返回值与 removeObjectForKey：相同，否则根据写入成功与否返回。
 */
- (BOOL)setObject:(nullable id)value forKey:(NSString *)key;

/**
 删除元素

 @param key 元素的key值

 @return 如果元素成功存在并成功倍删除，返回YES，否则返回NO
 */
- (BOOL)removeObjectForKey:(NSString *)key;


//----------------------------特定类型数据获取接口----------------------------

/// -stringForKey: is equivalent to -objectForKey:, except that it will convert NSNumber values to their NSString representation. If a non-string non-number value is found, nil will be returned.
- (nullable NSString *)stringForKey:(NSString *)key;

/// -arrayForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray.
- (nullable NSArray *)arrayForKey:(NSString *)key;
/// -dictionaryForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSDictionary.
- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)key;
/// -dataForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSData.
- (nullable NSData *)dataForKey:(NSString *)key;
/// -stringForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray<NSString *>. Note that unlike -stringForKey:, NSNumbers are not converted to NSStrings.
- (nullable NSArray<NSString *> *)stringArrayForKey:(NSString *)key;
/*!
 -integerForKey: is equivalent to -objectForKey:, except that it converts the returned value to an NSInteger. If the value is an NSNumber, the result of -integerValue will be returned. If the value is an NSString, it will be converted to NSInteger if possible. If the value is a boolean, it will be converted to either 1 for YES or 0 for NO. If the value is absent or can't be converted to an integer, 0 will be returned.
 */
- (NSInteger)integerForKey:(NSString *)key;
/// -floatForKey: is similar to -integerForKey:, except that it returns a float, and boolean values will not be converted.
- (float)floatForKey:(NSString *)key;
/// -doubleForKey: is similar to -doubleForKey:, except that it returns a double, and boolean values will not be converted.
- (double)doubleForKey:(NSString *)key;
/*!
 -boolForKey: is equivalent to -objectForKey:, except that it converts the returned value to a BOOL. If the value is an NSNumber, NO will be returned if the value is 0, YES otherwise. If the value is an NSString, values of "YES" or "1" will return YES, and values of "NO", "0", or any other string will return NO. If the value is absent or can't be converted to a BOOL, NO will be returned.
 
 */
- (BOOL)boolForKey:(NSString *)key;
/*!
 -URLForKey: is equivalent to -objectForKey: except that it converts the returned value to an NSURL. If the value is an NSString path, then it will construct a file URL to that path. If the value is an archived URL from -setURL:forKey: it will be unarchived. If the value is absent or can't be converted to an NSURL, nil will be returned.
 */
- (nullable NSURL *)URLForKey:(NSString *)key;

//----------------------------特定类型数据赋值接口----------------------------

/// -setInteger:forKey: is equivalent to -setObject:forKey: except that the value is converted from an NSInteger to an NSNumber.
- (BOOL)setInteger:(NSInteger)value forKey:(NSString *)key;
/// -setFloat:forKey: is equivalent to -setObject:forKey: except that the value is converted from a float to an NSNumber.
- (BOOL)setFloat:(float)value forKey:(NSString *)key;
/// -setDouble:forKey: is equivalent to -setObject:forKey: except that the value is converted from a double to an NSNumber.
- (BOOL)setDouble:(double)value forKey:(NSString *)key;
/// -setBool:forKey: is equivalent to -setObject:forKey: except that the value is converted from a BOOL to an NSNumber.
- (BOOL)setBool:(BOOL)value forKey:(NSString *)key;
/// -setURL:forKey is equivalent to -setObject:forKey: except that the value is archived to an NSData. Use -URLForKey: to retrieve values set this way.
- (BOOL)setURL:(nullable NSURL *)url forKey:(NSString *)key;

//----------------------------数据持久化接口----------------------------

/**
 同步持久化数据，调用线程将阻塞等待
 阻塞时间最长为1s
 1s后写入任务不会被取消，但是，返回NO
 @return 写入成功与否
 */
- (BOOL)synchronize;

/**
 异步持久化数据，持久化结果不可查询和获知
 */
- (void)asynchronize;    //异步持久化

@end

NS_ASSUME_NONNULL_END
