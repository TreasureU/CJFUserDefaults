//
//  CJFUserDefaults.m
//  iPadDemo
//
//  Created by ChengJianFeng on 16/9/28.
//  Copyright © 2016年 ChengJianFeng. All rights reserved.
//

#import "CJFUserDefaults.h"
#import "CJFBaseTools.h"
#import <pthread.h>
#import "CJFTargetConditionals.h"

#if CJF_HAS_UIKIT
#import <UIKit/UIKit.h>
#endif

#if CJF_HOST_MAC
#import <Cocoa/Cocoa.h>
#endif

static NSString* const CJFUserDefaultsDirName = @"CJFUserDefaultsDir";    //存放文件夹的名字
static NSString* const CJFUserDefaultsFileName = @"CJFUserDefaultsFile";  //存放文件的名字

static int const CJFUserDefaultsAutoSaveTimeSpace = 10.0;   //单位为s，自动保存间隔时间
static int const CJFUserDefaultsSyncWaitMaxTime = 1000;     //单位为ms，同步保存最长等待时间，避免死锁。

@interface CJFUserDefaults ()

@property(nonatomic,strong) NSMutableDictionary* dataDictionary;
@property(nonatomic,strong) NSOperationQueue* persistenceQueue;
@property(nonatomic,assign) BOOL writeSuc;  //仅用于读取同步持久化结果
@property(nonatomic,strong) NSTimer* saveTimer;

@end

@implementation CJFUserDefaults

#pragma mark - 生命周期

+(CJFUserDefaults *)standardUserDefaults {
    static dispatch_once_t pred;
    static CJFUserDefaults *shared = nil;
    dispatch_once(&pred, ^{
        //创建文件夹
        CJFBaseTools.creatDirInDocument(CJFUserDefaultsDirName);
        shared = [[super alloc] initUniqueInstance];
    });
    return shared;
}

-(instancetype) initUniqueInstance {
    if(self = [super init]){
        _dataDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:[CJFUserDefaults getDataStorePath]];
        if( _dataDictionary == nil ){
            _dataDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
        }
        
        _persistenceQueue = [[NSOperationQueue alloc] init];
        _persistenceQueue.maxConcurrentOperationCount = 1;
        
        _writeSuc = NO;
        
        [self resetSaveTimer];
        [self addObserver];
    }
    return self;
}

-(void)dealloc
{
    [self.saveTimer invalidate];
    self.saveTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+(NSString*)getDataStorePath
{
    return CJFBaseTools.getFilePath([NSString stringWithFormat:@"%@/%@",CJFUserDefaultsDirName,CJFUserDefaultsFileName]);
}

-(void)addObserver{
#if CJF_HAS_UIKIT
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
#endif
    
#if CJF_HOST_MAC
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
#endif
}

-(void)applicationDidEnterBackground:(NSNotification*)notify
{
    [self asynchronize];
}

-(void)applicationWillTerminate:(NSNotification*)notify
{
    [self asynchronize];
}

#pragma mark - 重置manager

-(void)resetStandardUserDefaults
{
    if( pthread_main_np() == 1 ){
        [self safeResetStandardUserDefaults];
    }else{
        __weak __typeof(self) weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf safeResetStandardUserDefaults];
        });
    }
}

//一定在主线程上执行
-(void)safeResetStandardUserDefaults{
    @synchronized ([CJFUserDefaults class]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.saveTimer invalidate];
        self.saveTimer = nil;
        [self.persistenceQueue cancelAllOperations];
        [self.persistenceQueue waitUntilAllOperationsAreFinished];
        self.dataDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL isExist = [fileManager fileExistsAtPath:[CJFUserDefaults getDataStorePath] isDirectory:&isDir];
        if( isExist && !isDir ){
            [fileManager removeItemAtPath:[CJFUserDefaults getDataStorePath] error:nil];
        }
        [self resetSaveTimer];
        [self addObserver];
    }
}

-(void)resetSaveTimer{
    if( self.saveTimer ){
        [self.saveTimer invalidate];
        self.saveTimer = nil;
    }
    //在主线程上触发自动保存，内部使用异步同步化方法
    self.saveTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:CJFUserDefaultsAutoSaveTimeSpace] interval:CJFUserDefaultsAutoSaveTimeSpace target:self selector:@selector(autoSaveMethod:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.saveTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark - 数据读取

-(id)objectForKey:(NSString *)key
{
    if( ![key isKindOfClass:[NSString class]] ){
        return nil;
    }
    @synchronized ([CJFUserDefaults class]) {
        return self.dataDictionary[key];
    }
}

#pragma mark - 数据写入

- (BOOL)setObject:(nullable id)value forKey:(NSString *)key
{
    if( CJFBaseTools.validatePropetyList(value) ){
        return [self writeValidateValue:value forKey:key];
    }else if( [value isKindOfClass:[NSURL class]] ){
        return [self setURL:value forKey:key];
    }else if( value == nil ){
        return [self removeObjectForKey:key];
    }
    return NO;
}

-(BOOL)removeObjectForKey:(NSString*)key
{
    if( ![key isKindOfClass:[NSString class]] ){
        return NO;
    }
    @synchronized ([CJFUserDefaults class]) {
        if( self.dataDictionary[key] != nil){
            [self.dataDictionary removeObjectForKey:key];
            return YES;
        }else{
            return NO;
        }
    }
}

-(BOOL)writeValidateValue:(id)value forKey:(NSString*)key
{
    if( ![key isKindOfClass:[NSString class]] ){
        return NO;
    }
    @synchronized ([CJFUserDefaults class]) {
        self.dataDictionary[key] = value;
        return YES;
    }
}

#pragma mark - 特定类型数据获取操作

- (nullable NSString *)stringForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value isKindOfClass:[NSNumber class]] ){
        value = [(NSNumber*)value stringValue];
    }
    if( value && ![value isKindOfClass:[NSString class]] ){
        value = nil;
    }
    return value;
}

- (nullable NSArray *)arrayForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value  isKindOfClass:[NSArray class]] ){
        return value;
    }else{
        return nil;
    }
}

- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value  isKindOfClass:[NSDictionary class]] ){
        return value;
    }else{
        return nil;
    }
}

- (nullable NSData *)dataForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value  isKindOfClass:[NSData class]] ){
        return value;
    }else{
        return nil;
    }
}

- (nullable NSArray<NSString *> *)stringArrayForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value  isKindOfClass:[NSArray class]] ){
        BOOL isRight = YES;
        for (id obj in value) {
            if( ![obj isKindOfClass:[NSString class]] ){
                isRight = NO;
                break;
            }
        }
        if( isRight ){
            return value;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

- (NSInteger)integerForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value isKindOfClass:[NSNumber class]] ){
        return [(NSNumber*)value integerValue];
    }else if ( value && [value isKindOfClass:[NSString class]] ){
        return [(NSString*)value integerValue];
    }else{
        return 0;
    }
}

- (float)floatForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value isKindOfClass:[NSNumber class]] ){
        return [(NSNumber*)value floatValue];
    }else if ( value && [value isKindOfClass:[NSString class]] ){
        return [(NSString*)value floatValue];
    }else{
        return 0.0;
    }
}

- (double)doubleForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value isKindOfClass:[NSNumber class]] ){
        return [(NSNumber*)value doubleValue];
    }else if ( value && [value isKindOfClass:[NSString class]] ){
        return [(NSString*)value doubleValue];
    }else{
        return 0.0;
    }
}

- (BOOL)boolForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value isKindOfClass:[NSNumber class]] ){
        return [(NSNumber*)value boolValue];
    }else if ( value && [value isKindOfClass:[NSString class]] ){
        if( [@"YES" isEqualToString:value] || [@"1" isEqualToString:value]){
            return YES;
        }else{
            return NO;
        }
    }else{
        return NO;
    }
}

- (nullable NSURL *)URLForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    if( value && [value isKindOfClass:[NSString class]] ){
        NSURL* url = [[NSURL alloc] initWithString:value];
        return url;
    }else if ( value && [value isKindOfClass:[NSData class]] ){
        value = [NSKeyedUnarchiver unarchiveObjectWithData:value];
        if( [value isKindOfClass:[NSURL class]] ){
            return value;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

#pragma mark - 特定类型数据赋值

- (BOOL)setInteger:(NSInteger)value forKey:(NSString *)key
{
    return [self setObject:[NSNumber numberWithInteger:value] forKey:key];
}

- (BOOL)setFloat:(float)value forKey:(NSString *)key
{
    return [self setObject:[NSNumber numberWithFloat:value] forKey:key];
}

- (BOOL)setDouble:(double)value forKey:(NSString *)key
{
    return [self setObject:[NSNumber numberWithDouble:value] forKey:key];
}

- (BOOL)setBool:(BOOL)value forKey:(NSString *)key
{
    return [self setObject:[NSNumber numberWithBool:value] forKey:key];
}

- (BOOL)setURL:(nullable NSURL *)url forKey:(NSString *)key
{
    if( ![url isKindOfClass:[NSURL class]] ){
        return NO;
    }
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:url];
    return [self setObject:data forKey:key];
}

#pragma mark - 数据持久化

- (BOOL)synchronize
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __weak __typeof(self) weakSelf = self;
    [self.persistenceQueue addOperationWithBlock:^{
        __strong __typeof(self) strongSelf = weakSelf;
        NSDictionary* writerDic = nil;
        @synchronized ([CJFUserDefaults class]) {
            writerDic = [strongSelf.dataDictionary copy];
        }
        strongSelf.writeSuc =  [writerDic writeToFile:[CJFUserDefaults getDataStorePath] atomically:YES];
        dispatch_semaphore_signal(semaphore);
    }];
    long time =  dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, CJFUserDefaultsSyncWaitMaxTime * NSEC_PER_MSEC));
    if( time > 0 ){
        return NO;
    }else{
        return self.writeSuc;
    }
}

- (void)asynchronize
{
    __weak __typeof(self) weakSelf = self;
    [self.persistenceQueue addOperationWithBlock:^{
        __strong __typeof(self) strongSelf = weakSelf;
        NSDictionary* writerDic = nil;
        @synchronized ([CJFUserDefaults class]) {
            writerDic = [strongSelf.dataDictionary copy];
        }
        [writerDic writeToFile:[CJFUserDefaults getDataStorePath] atomically:YES];
    }];
}

-(void)autoSaveMethod:(NSTimer*)timer
{
    [self asynchronize];
}

@end
