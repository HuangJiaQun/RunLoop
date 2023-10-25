//
//  MCObject.m
//  RunLoop
//
//  Created by 黄 嘉群 on 2023/10/23.
//  Copyright © 2023 黄嘉群. All rights reserved.
//

#import "MCObject.h"
//定义两个k静态全局变量
static NSThread *thread =nil;
// 标记当前线程是否要继续事件循环
static BOOL runAlways = YES;


//+ (NSThread *)threadForDispatch{
//    if (thread == nil) {
//        @synchronized(self) {
//            if (thread == nil) {//采用线程安全的方式去创建thread,入口方法为runRequest
//                // 线程的创建
//                thread = [[NSThread alloc] initWithTarget:self selector:@selector(runRequest) object:nil];
//                [thread setName:@"com.imooc.thread"];
//                // 启动
//                [thread start];
//            }
//        }
//    }
//    return thread;
//}


@implementation MCObject
/*
•为当前线程开启一个RunLoop
可以通过[CFRunLoop getCurrent]或者 [NSRunLoop currentRunLoop]来创建，,因为获取RunLOop这个方法本身
会查找,如果当前线程没有runloop,会在系统内部为我们创建
•向该RunLoop中添加一个port / Source等维护RunLoop的事件循环
RunLoop如果没有事件需要处理的话,默认情况下，是不能自己维持事件循环,会直接退出,所以需要添加port / So
urce来维持事件循环机制
•启动该RunLoop
调用rUn方法
。运行的模式和上面添加资源的模式必须是同一个，否则会因为外部使用个while循环就导致死循环。
 */

+ (NSThread*)threadForDispatch{
    @synchronized (self) {
        if(thread==nil){
            //采用线程安全的方式去创建thread,入口方法为runRequest
            // 线程的创建
            thread = [[NSThread alloc]initWithTarget:self selector:@selector(runRequest) object:nil];
            [thread setName:@"com.imooc.thread"];
            [thread start];
        }
    }
    return thread;
}


+ (void)runRequest
{
    // 创建一个Source
    CFRunLoopSourceContext context = {0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
    CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);

    // 为thread线程创建RunLoop，同时向RunLoop的DefaultMode下面添加Source
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);

    //while循环维持RunLoop的事件循环
    // 如果可以运行
    while (runAlways) {
        //确保每次yRunLoop运行一圈的时候能够对内存进行释放
        @autoreleasepool {
            /* 令当前RunLoop运行在DefaultMode下面,注意这个运行的mode和上面添加资源的mode必须是同一个mode
               否则把事件源添加到另一个mode上,而运行的defaultMode下,是无法维持运行的
               函数内部会调用mach_msg,发生由用户态到核心态的切换,当前线程就会休眠,就停在里面,不是死循环
               1.0e10是让循环运行到指定时间退出,这个代表很久远的时间
               true代表资源被处理后是否马上返回
             */
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0e10, true);
        }
    }

    // 如果Runloop的mode中没有对应的事件源可以处理,runloop就会自动退出
    // 所以我们在某一时机 将source移除,静态变量runAlways = NO时 可以保证跳出RunLoop，线程退出并s释放掉
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CFRelease(source);
}


//怎样保证子线程数据回来更新U的时候，不打断用户的滑动操作？
//在用户进行滑动的过程中，当前的RunLoop运行在UITrackingRunLoopMode模式下，而我们一般对网络请求是放在子线程中,子线程返回给主线程的数据要抛给主线程用来更新UI，可以把这部分逻辑包装起来,提交到主线程的cefault模式 下,这样的话,当用户滑动时,default模式 下的任务不会执
//行，
//当用户手停止时,mode就切换到了 default模式下,就会处理子线程的数据了,这样就不会打断用户的滑动操作了
//1、把子线程抛给主线程进行U更新的逻辑，可以包装起来，提交到主线程的NSDefaultRunLoopMode模式下
//面。
//2、因为用户滑动操作是在UITrackingRunLoopMode模式下进行的。
//参考代码事件
//[self.tableView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
@end
