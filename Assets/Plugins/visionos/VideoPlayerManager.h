// VideoPlayerManager.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

extern "C" typedef void (*OnPlayerInitCallback)(const char*, int, int);
extern "C" typedef void (*OnExternalTextureUpdate)(int, int, void*);
extern "C" typedef void (*OnNormalTextureUpdate)(int, int, void*, int);

@interface VideoPlayerManager : NSObject

+ (instancetype)sharedInstance;
- (void)playVideoWithURL:(NSString *)urlString : (OnPlayerInitCallback)cb;
- (id<MTLTexture>)getTextureForCurrentFrame;
- (void)tryCopyPixelBufferToUnity;

@end
