//
//  main.m
//  RunLoop
//
//  Created by 黄嘉群 on 2020/3/22.
//  Copyright © 2020 黄嘉群. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        //1：什么是runloop？----------------------------------------------------------
        //RunLoop是通过内部维护的事件循环来对事件/消息进行管理的一个对象
        
        //2:事件循环是什么--------------------------------------------------------------
        //没有消息时，休眠以避免资源占用，有消息时，立刻被唤醒。不是一个单纯的do while循环，他是一个用户态到内核态的一个切换，以及内核态到用户态的一个切换，他维护事件循环，可以不不断的处理消息或者事件，比如定时器，网络请求，用户操作，触摸事件，对他们进行管理，当没有消息处理时，会从用户态切换的内核态，由此当前进程或者线程休眠，把控制权交个内核态，避免资源占用。当有消息处理时会从内核态切换到用户态，当前线程会被唤醒，状态切换才是关键。
        
        //3:main函数为何会保持不退出----------------------------------------------------------------
        //程序中默认从主函数main函数中启动，顺着代码开始执行推出，最后main函数推出，程序也推出，但是现在main函数中会调用UIApplicationMain函数，在内部会启动Runloop,可以不断的接受消息，比如屏幕点击，滑动列表，网络请求的返回等，接受消息后对事件进行处理，处理完以后继续等待。
        
        
        //4:Runloop数据结构----------------------------------------------------------------
        /*OC中实际提供两个Runloop:
         CFRunloop:cfrunloop位于corefoundation中；
         NSRunoop:位于foundation中，是对CFRunloop的封装，提供啦面向对象的api;
         
        Runloop数据结构有三个：CFRunloop,CFRunloopMode,source/timer/observer;
         struct __CFRunLoop {
             CFRuntimeBase _base;
         
             //C级别的一个线程对象 , RunLoop和线程是一一对应的关系
             //pthread_t _pthread;
             
            //数据结构：NSMutableSet<CFRunLoopMode*>表示一个可变集合，其中的元素都是 CFRunLoopMode 对象的指针。CFRunLoopMode 是与 Runloop 相关的核心基础类型，它用于管理 Runloop 的运行模式。在实际应用中，你可以使用这个集合来存储一组不同的运行模式，用于配置 Runloop 的行为。
             //CFRunLoopModeRef _currentMode;
         
             //多个mode的集合，从数据结构看出，RunLoop和它的mode是一对多的关系
             //CFMutableSetRef _modes;

             //也是一个集合里面都是字符串，有别于_modes里面的元素CFRunLoopModeRef
            // CFMutableSetRef _commonModes;
         
             //也是一个集合，包含多个Observer(观察者)、Timer、Source。 我们可以为RunLoop添加Observer(观察者)，包括Timer、Source都可以提交到某一个RunLoop对应的某一个_currentMode上面。
             //CFMutableSetRef _commonModeItems;
            
         //};
         
         
         CFRunLoop具体成员变量
         struct __CFRunLoopMode {
             CFStringRef _name;            // Mode Name, 例如 @"kCFRunLoopDefaultMode"
             CFMutableSetRef _sources0;    // 结构
             CFMutableSetRef _sources1;    // Set
             CFMutableArrayRef _observers; // Array
             CFMutableArrayRef _timers;    // Array
             ...
         };
         
         
         CFRunLoopSource
         在CF框架当中官方名称叫 CFRunLoopSource，有两种 source0 和 source1
         _sources0：这是一个直接事件源（Sources）的阵列，它用于处理来自基于内核的事件源的事件。这些事件通常是由底层系统或硬件设备触发的，如触摸事件、按键事件等。通常包含_sources0了一些Mach端口（Mach Ports）等，用于接收这些事件。
         _sources1：这是一个间接事件源的队列，用于处理来自其他线程或程序组件的事件，通常是通过线程间通信机制，如 GCD 或 CFMessagePort 进行发送的。存储了这些事件源，使得能够在合适的情况下_sources1进行CFRunLoop处理时机处理这些事件。
         唤醒线程就是从内核态切换到用户态
         
         CFRunLoopTimer
         和平时所使用的 NSTimer 是具备免费桥转换的
         
         CFRunLoopObserver
         观测时间点
         • KCFRunLoopEntry：当RunLoop启动时，系统给我们的会调通知
         
         • KCFRunLoopBeforeTimers：通知观察者将要对timers相关事件作处理
         
         • KCFRunLoopBeforeSources：将要处理Sources事件
         
         • KCFRunLoopBeforeWaiting：通知观察者RunLoop将要休眠，非常重要观测点，RunLoop发送这个通知的时候，将要发生用户态到内核态的切换。
         • KCFRunLoopAfterWaiting：代表啦内核态切换到用户态到不久之后。
         
         • KCFRunLoopExit：RunLoop推出的通知。
        */
        
        
       // RunLoop 的Mode----------------------------------------------------------
       /* 一个RunLoop可以对应多个mode，每个mode 当中又可以有多个 Sources1, Timers, Observers
        当 RunLoop 运行在某一个mode 上的时候，比如说运行在mode1 上面，这个时候如果 mode2 当中某一个 timer
        事件或者 Observe 事件回调了，这个时候是没有办法接收对应 mode2 当中所回调过来的事件，这就 RunLoop
        有多个mode 的原因，实际上起到的就是一个屏蔽的效果，当运行到 mode1 上时，只能接收处理mode1 当中的
        Sources1, Timers, Observers
        
        
        思考：一个 Timer 要想同时加入到两个mode 里面，需要怎么做？如果说这个 Timer 既想要它在mode1 上可以正常运行，在每一个事件回调中做正常的处理，在mode2 上也需要做相应的处理和事件的回调接收
        系统提供了添加到两个 mode 的机制的，这样可以保证当 RunLoop 发生mode 切换的时候也可以让对应的Timer等事件正常外理接收
        这实际上就涉及到了 CommonMode (CommonMode 的特殊性）：----------------------------------------------------------
        commonMode 本身是有它的特殊性的，CommonMode 并不是一个实际存在的模式，在0C 当中经常会通过 NS
        RunLoopCommonModes 字符串常量来表达 CommonMode
        CommonMode 本身和 defaultMode 是有区分的，调用一个线程运行在CommonMode上面和运行在具体的 defa ultMode上是有区别的这里有个概念叫“CommonModes”：—个Mode可以将自己标记为”Common”属性(通过将其 ModeName 添加到 RunLoop 的“commonModes” 中）。每当RunLoop 的内容发生变化时，RunLoop 都会自动将_commonModeltems 里的 Source/Observer/Timer 同步到具有“Common”标记的所有Mode里。
        
        应用场景举例：主线程的 RunLoop 里有两个预置的 Mode: KCFRunLoopDefaultMode 和 UITrackingRunLoopMode。这两个Mode都已经被标记为”Common”属性。DetaultMode 是 App 平时所处的状态，TrackingRunLoopMoode 是追踪 Scrolview 滑动时的状态。当你创建一个 Timer 并加到DefaultMode 时， Timer 会得到重复回调，但此时滑动一个Tableview时，RunLoop 会将mode 切换为 Tracking RunLoopMode， 这时 Timer 就不会被回调，并且也不会影响到滑动操作。有时你需要一个 Timer， 在两个 Mode 中都能得到回调，一种办法就是将这个 Timer 分别加入这两个 Mode。还有一种方式，就是将 Timer 加入到顶层的RunLoop 的“commonModeltems” 中。”commonModeltems”被 RunLoop 自动更新到所有具有”Common”属性的Mode 里去。
        
        
        */
        
        
        /*什么是RunLoop？它是怎么做到有事做事，没事休息的？
         1、RunLoop是通过内部维护的事件循环来对事件/消息进行管理的一个对象。
         2、程序运行会调用main函数，在main函数里面调用UIApplicationMain, UIApplicationMain函数会启动主线程的
         runloop.
         3、runloop运行后，会调用系统方法mach_msg0，会使得程序从用户态变成核心态，此时线程处于休眠状态。
         4、当有外界条件变化(Source/Timer/Observer)，mach_msg会使得程序从核心态变成用户态，此时线程处于活
         跃状态。
         RunLoop与线程是怎么样的关系
         1、RunLoop与线程是一一对应的关系。
         2、一个线程默认是没有runloop的(主线程除外），我们需要为它手动创建。*/
        
        
        
        
        
    }
}
