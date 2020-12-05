//
//  ViewController.m
//  RunLoop
//
//  Created by 黄嘉群 on 2020/3/22.
//  Copyright © 2020 黄嘉群. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self MyscrollView];
//    简单的说run loop是事件驱动的一个大循环，如下代码所示
//    int main(int argc, char * argv[]) {
//        //程序一直运行状态
//        while (AppIsRunning) {
//            //睡眠状态，等待唤醒事件
//            id whoWakesMe = SleepForWakingUp();
//            //得到唤醒事件
//            id event = GetEvent(whoWakesMe);
//            //开始处理事件
//            HandleEvent(event);
//        }
//        return 0;
//    }
    
//    在Main thread堆栈中所处位置
//    堆栈最底层是start(dyld)，往上依次是main，UIApplication(main.m) -> GSEventRunModal(Graphic Services) -> RunLoop(包含CFRunLoopRunSpecific，CFRunLoopRun，__CFRunLoopDoSouces0，__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION) -> Handle Touch Event
    
    
    //Cocoa会涉及到Run Loops的
//    系统级：GCD，mach kernel，block，pthread
//  应用层：NSTimer，UIEvent，Autorelease，NSObject(NSDelayedPerforming)，NSObject(NSThreadPerformAddition)，CADisplayLink，CATransition，CAAnimation，dispatch_get_main_queue()（GCD中dispatch到main queue的block会被dispatch到main RunLoop执行），NSPort，NSURLConnection，AFNetworking(这个第三方网络请求框架使用在开启新线程中添加自己的run loop监听事件)
    
//    构成
//    Thread包含一个CFRunLoop，一个CFRunLoop包含一种CFRunLoopMode，mode包含CFRunLoopSource，CFRunLoopTimer和CFRunLoopObserver。
    
    
    
    //2.AFNEetworking进行网络请求时底层单独起一个global thread=全局线程，内置一个runloop,所有的connection=连接都由这个Runloop发起，回调也是他接受，不占用主线程，也不耗CPU资源。
//    TableView中实现平滑滚动延迟加载图片
    
//    利用CFRunLoopMode的特性，可以将图片的加载放到NSDefaultRunLoopMode的mode里，这样在滚动UITrackingRunLoopMode这个mode时不会被加载而影响到。
//    UIImage *downloadedImage = ...;
//    [self.avatarImageView performSelector:@selector(setImage:)
//                               withObject:downloadedImage
//                               afterDelay:0
//                                  inModes:@[NSDefaultRunLoopMode]];
//
//        TableView中实现平滑滚动延迟加载图片
//        利用CFRunLoopMode的特性，可以将图片的加载放到NSDefaultRunLoopMode的mode里，这样在滚动UITrackingRunLoopMode这个mode时不会被加载而影响到。
//        UIImage *downloadedImage = ...;
//        [self.avatarImageView performSelector:@selector(setImage:)
//                                   withObject:downloadedImage
//                                   afterDelay:0
//                                      inModes:@[NSDefaultRunLoopMode]];
//
//
//        接到程序崩溃时的信号进行自主处理例如弹出提示等
//        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
//        NSArray *allModes = CFBridgingRelease(CFRunLoopCopyAllModes(runLoop));
//        while (1) {
//            for (NSString *mode in allModes) {
//                CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
//            }
//        }
    
}

- (void)MyscrollView{
    //1.Timer计时会被scrollView的滑动影响的问题可以通过timer添加到NSRunloopCommonModes来解决
    //将timer添加到NSDefaultRunLoopMode中:
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    //然后在添加到NSRunLoopCommonModes即放到mode的集合里面:
    NSTimer*timer=[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
    
    
}

- (void)timerTick:(NSTimer*)time{
    NSLog(@"time");
}

    //2.AFNEetworking进行网络请求时底层单独起一个global thread=全局线程，内置一个runloop,所有的connection=连接都由这个Runloop发起，回调也是他接受，不占用主线程，也不耗CPU资源。
+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"AFNetworking"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread*)networkRequestThread{
    static NSThread*networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        networkRequestThread=[[NSThread alloc]initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [networkRequestThread start];
    });
    return networkRequestThread;
}

//异步测试
- (BOOL)runUntilBlock:(BOOL(^)(void))block timeout:(NSTimeInterval)timeout
{
    __block Boolean fulfilled = NO;
    void (^beforeWaiting) (CFRunLoopObserverRef observer, CFRunLoopActivity activity) =
    ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        fulfilled = block();
        if (fulfilled) {
            CFRunLoopStop(CFRunLoopGetCurrent());
        }
    };
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, true, 0, beforeWaiting);
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
    
    // Run!
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, timeout, false);
    
    CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
    CFRelease(observer);
    
    return fulfilled;
}


@end
