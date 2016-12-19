//
//  CJFTargetConditionals.h
//  CommandDemo
//
//  Created by ChengJianFeng on 2016/12/14.
//  Copyright © 2016年 ChengJianFeng. All rights reserved.
//

#ifndef CJFTargetConditionals_h
#define CJFTargetConditionals_h

#include <TargetConditionals.h>

//定义自己的平台宏
#define CJF_HOST_IOS TARGET_OS_IOS
#define CJF_HOST_TV TARGET_OS_TV
#define CJF_HOST_WATCH TARGET_OS_WATCH
#define CJF_HOST_MAC (TARGET_OS_MAC && !(TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH))

//UIKIT相关宏
#if CJF_HOST_IOS || CJF_HOST_TV
#define CJF_HAS_UIKIT 1
#else
#define CJF_HAS_UIKIT 0
#endif

//thread API相关宏
#if CJF_HOST_MAC || CJF_HOST_IOS || CJF_HOST_TV
#define CJF_HAS_THREADS_API 1
#else
#define CJF_HAS_THREADS_API 0
#endif

//reachability相关宏
#if CJF_HOST_MAC || CJF_HOST_IOS || CJF_HOST_TV
#define CJF_HAS_REACHABILITY 1
#else
#define CJF_HAS_REACHABILITY 0
#endif

#endif /* CJFTargetConditionals_h */
