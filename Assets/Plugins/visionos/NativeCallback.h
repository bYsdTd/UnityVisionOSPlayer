//
//  NativeCallbac.h
//  UnityFramework
//
//  Created by ByteDance on 2023/11/30.
//

// VideoPlayerManager.h

#import <Foundation/Foundation.h>

@interface NativeCallback : NSObject

+ (instancetype)sharedInstance;
- (void)callObjectC:(NSString *)message;

@end

