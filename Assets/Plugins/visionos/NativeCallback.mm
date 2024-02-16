// NativeCallback.mm

#import "NativeCallback.h"

// 导出方法供Unity调用
extern "C" {
    typedef void (*CallbackFromObjectC)(const char*);
    void RegisterNativeCallback(CallbackFromObjectC cb) {
        NSString* message = [NSString stringWithUTF8String:"OC:  RegisterNativeCallback"];
        [[NativeCallback sharedInstance] callObjectC:message];
    }
}

@implementation NativeCallback

+ (instancetype)sharedInstance {
    static NativeCallback *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)callObjectC:(NSString *)message{
    NSLog(@"callObjectC %@ ", message);
}

@end
