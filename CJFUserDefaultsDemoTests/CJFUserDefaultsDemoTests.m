//
//  CJFUserDefaultsDemoTests.m
//  CJFUserDefaultsDemoTests
//
//  Created by ChengJianFeng on 2016/12/14.
//  Copyright © 2016年 ChengJianFeng. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CJFUserDefaults.h"

static NSString* const testKeyName = @"testkey";
static NSString* const testValue = @"testValue";

@interface CJFUserDefaultsDemoTests : XCTestCase

@end

@implementation CJFUserDefaultsDemoTests

- (void)setUp {
    [super setUp];
    [[CJFUserDefaults standardUserDefaults] setObject:testValue forKey:testKeyName];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSLog(@"%s",__FUNCTION__);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    NSLog(@"%s",__FUNCTION__);
     [[CJFUserDefaults standardUserDefaults] setObject:nil forKey:testKeyName];
    [[CJFUserDefaults standardUserDefaults] synchronize];
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSLog(@"%s",__FUNCTION__);
    NSString* value = [[CJFUserDefaults standardUserDefaults] objectForKey:testKeyName];
    XCTAssert(value);
    if( [value isKindOfClass:[NSString class]] && [testValue isEqualToString:value] ){
        NSLog(@"Test is right. value is %@",value);
    }else{
        NSLog(@"Test is error.");
    }
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        NSLog(@"%s",__FUNCTION__);
    }];
}

@end
