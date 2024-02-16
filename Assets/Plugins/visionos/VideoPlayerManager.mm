// VideoPlayerManager.m

#import "VideoPlayerManager.h"
#import <CoreVideo/CoreVideo.h>
#import <UnityFramework/UnityFramework.h>

OnExternalTextureUpdate externalTexUpdateCallback;
OnNormalTextureUpdate normalTexUpdateCallback;

// 导出方法供Unity调用
extern "C" {

    void _PlayVideoWithURL(const char* urlString, OnPlayerInitCallback cb) {
        NSString *urlStringObj = [NSString stringWithUTF8String:urlString];
        [[VideoPlayerManager sharedInstance] playVideoWithURL:urlStringObj:cb];
    }

    void* GetTextureForCurrentFrame() {
        id<MTLTexture> texture = [[VideoPlayerManager sharedInstance] getTextureForCurrentFrame];
        if (texture) {
            return (__bridge void *)(texture);
        }
        return NULL;
    }

    void TryCopyPixelBufferToUnity() {
        [[VideoPlayerManager sharedInstance] tryCopyPixelBufferToUnity];
    }

    void RegisterNormalTextureUpdate(OnNormalTextureUpdate normalTexUpdate){
        normalTexUpdateCallback = normalTexUpdate;
    }

    void RegisterExternalTextureUpdate(OnExternalTextureUpdate externalCallback){
        externalTexUpdateCallback = externalCallback;
    }
}

@interface VideoPlayerManager ()
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItemVideoOutput *videoOutput;
@property (strong, nonatomic) id<MTLDevice> metalDevice;
@property CVMetalTextureCacheRef textureCache;
@property int width;
@property int height;
@end


@implementation VideoPlayerManager

+ (instancetype)sharedInstance {
    static VideoPlayerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)playVideoWithURL:(NSString *)urlString : (OnPlayerInitCallback)cb{

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlString]];
    
    [self setupVideoOutputWithPlayerItem:playerItem];

    _player = [AVPlayer playerWithPlayerItem:playerItem];
    // ...其他配置...
    [_player play];
    
    // 开始播放，通知Unity
    cb("The Player has started!", _width, _height);
    PlayerDidStart();

}

// 假设播放器开始播放
void PlayerDidStart() {
    
    [[UnityFramework getInstance] sendMessageToGOWithName:"360ERP" functionName:"OnPlayerStarted" message:"Message From OC By send message"];
    
//    UnitySendMessage("Sphere_360EAC", "OnPlayerStarted", "The player has started.");
}

- (void)setupVideoOutputWithPlayerItem:(AVPlayerItem*)playerItem {

    _metalDevice = MTLCreateSystemDefaultDevice();
    CVMetalTextureCacheCreate(NULL, NULL, _metalDevice, NULL, &_textureCache);
    // 设置视频输出
    NSDictionary *outputAttributes = @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) ,
        (NSString *)kCVPixelBufferMetalCompatibilityKey: @YES
    };
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:outputAttributes];
    // 将视频输出添加到播放器项
    [playerItem addOutput:_videoOutput];
}

- (id<MTLTexture>)getTextureForCurrentFrame {
    CMTime itemTime = [_videoOutput itemTimeForHostTime:CACurrentMediaTime()];
    if ([_videoOutput hasNewPixelBufferForItemTime:itemTime]) {
        CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
        if (pixelBuffer) {
            
            // 获取尺寸
            _width = (int)CVPixelBufferGetWidth(pixelBuffer);
            _height = (int)CVPixelBufferGetHeight(pixelBuffer);

            // 获取格式
//            OSType pixelFormatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
            
            CVMetalTextureRef metalTextureRef = NULL;
            CVReturn status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, pixelBuffer, NULL, MTLPixelFormatRGBA8Unorm, _width, _height, 0, &metalTextureRef);
            CVPixelBufferRelease(pixelBuffer);

            if(status == kCVReturnSuccess) {
                id<MTLTexture> metalTexture = CVMetalTextureGetTexture(metalTextureRef);
                CFRelease(metalTextureRef);
                externalTexUpdateCallback(_width, _height, (__bridge void *)(metalTexture));
                return metalTexture;
            }
        }
    }
    return nil;
}

- (void)tryCopyPixelBufferToUnity{
    
    NSLog(@"OC: tryCopyPixelBufferToUnity");
    
    CMTime itemTime = [_videoOutput itemTimeForHostTime:CACurrentMediaTime()];
    if ([_videoOutput hasNewPixelBufferForItemTime:itemTime]) {
        CVPixelBufferRef pixelBuffer = [_videoOutput copyPixelBufferForItemTime:itemTime itemTimeForDisplay:nil];
        if (pixelBuffer) {
            
            // 获取尺寸
            _width = (int)CVPixelBufferGetWidth(pixelBuffer);
            _height = (int)CVPixelBufferGetHeight(pixelBuffer);
            
            //通过如下API拿到该图像的宽、高、每行的字节数、每个像素的字节数
            size_t r = CVPixelBufferGetBytesPerRow(pixelBuffer);
            size_t bytesPerPixel = r/_width;
            OSType bufferPixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
            NSLog(@"GEMFIELD whrb: %d - %d - %zu - %zu - %u",_width,_height,r,bytesPerPixel,bufferPixelFormat);
            
            // 执行拷贝
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            
            void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
            size_t dataSize = CVPixelBufferGetDataSize(pixelBuffer);
//            size_t dataSize = _width * _height * bytesPerPixel;
            
            // 回调创建texture 2d 并拷贝内存
            normalTexUpdateCallback(_width, _height, baseAddress, (int)dataSize);
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            
            CVPixelBufferRelease(pixelBuffer);
        }
    }
}

@end
