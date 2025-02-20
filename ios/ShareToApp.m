#import <React/RCTBridgeModule.h>
#import <Photos/Photos.h>


@interface RCT_EXTERN_MODULE(ShareToApp, NSObject)

RCT_EXTERN_METHOD(getFileNames:(NSString)url
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject);

RCT_EXTERN_METHOD(clearFileNames)


@end
