//
//  ViewController.m
//  GCD
//
//  Created by Garen on 16/9/7.
//  Copyright © 2016年 huaying. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self syncAndConcurrentQueue];
//    [self synAndSerialQueue];
//    [self queue];
//    [self dispatchAfter];
//    [self dispatchGroup];
//    [self dispatchApply];
//    [self dispatchBarrier];
//    [self threadSync];
    [self test];
    
}

- (void)test {
    dispatch_queue_t serial_queue = dispatch_queue_create("serial_queue", DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(serial_queue, ^{
        sleep(1);
        NSLog(@"1");
    });
    dispatch_async(serial_queue, ^{
        sleep(1);
        NSLog(@"2");
    });
    
    sleep(1);
    //挂起和重新唤醒队列，对已经执行的任务不起作用，线程挂起后，派发队列中从第一个未开始执行的任务开始暂停执行，线程恢复后，再由停止的地方重新开始执行
    dispatch_suspend(serial_queue);
    NSLog(@"suspend");
    
    dispatch_async(serial_queue, ^{
        NSLog(@"3");
    });
    
    dispatch_resume(serial_queue);
    NSLog(@"resume");
    
    dispatch_async(serial_queue, ^{
        sleep(1);
        NSLog(@"4");
    });
}

- (void)threadSync {
    
    dispatch_queue_t concurrent_queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    
    //确保block内代码在整个应用运行期间只执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"just run once in application");
    });
    
    //同步锁，对block内的代码加锁,同一时间内只允许一个线程访问
    @synchronized(self) {
        NSLog(@"lock");
    };
    
    //信号量dispatch_semaphore
    dispatch_group_t group = dispatch_group_create();
    
    //设置总信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
    for (int i = 0; i<100; i++) {
        //设置等待信号，如果此时信号量大于0，那么信号量减一并继续往下执行
        //如果此时信号量小于0，会一直等待，直到超时
        //如果超时返回非零，成功执行返回0
        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*50));
        
        dispatch_group_async(group, concurrent_queue, ^{
            sleep(1);
            NSLog(@"%d",i);
            //发送信号，让信号量加一
            dispatch_semaphore_signal(semaphore);
        });
    }
    
    dispatch_group_notify(group, concurrent_queue, ^{
        NSLog(@"finish");
    });
    
}

//栅栏必须单独执行，不能与其他任务并发执行，因此，栅栏只对并发队列有意义。栅栏只有等待当前队列所有并发任务都执行完毕后，才会单独执行，待其执行完毕，再按照正常的方式继续向下执行。
- (void)dispatchBarrier {
    dispatch_queue_t concurrent_queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_async(concurrent_queue, ^{
        sleep(2);
        NSLog(@"1");
    });
    dispatch_async(concurrent_queue, ^{
        sleep(2);
        NSLog(@"2");
    });
    dispatch_async(concurrent_queue, ^{
        sleep(2);
        NSLog(@"3");
    });
    
    dispatch_barrier_async(concurrent_queue, ^{
        sleep(2);
        NSLog(@"barrier");
    });
    dispatch_async(concurrent_queue, ^{
        sleep(2);
        NSLog(@"finish1");
    });
    
    dispatch_async(concurrent_queue, ^{
        NSLog(@"finish2");
    });

    
}

//将一个任务提交到队列中重复执行，并行或者串行由队列决定，dispatch_apply会阻塞当前线程，等到所有任务完成后返回
- (void)dispatchApply {
    dispatch_queue_t concurrent_queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(5, concurrent_queue, ^(size_t index) {
        sleep(1);
        NSLog(@"index:%zu",index);
    });
    NSLog(@"finish");
}


- (void)dispatchGroup {
    dispatch_queue_t serial_queue = dispatch_queue_create("serial.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t concurrent_queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_group_t group = dispatch_group_create();
    
//    /**
//     *  group中所有任务任务执行完毕后，执行dispatch_group_notify中的任务
//     */
//    dispatch_group_async(group, serial_queue, ^{
//        sleep(2);
//        NSLog(@"serial_queue1");
//    });
//    dispatch_group_async(group, serial_queue, ^{
//        sleep(2);
//        NSLog(@"serial_queue2");
//    });
//    dispatch_group_async(group, concurrent_queue, ^{
//        sleep(2);
//        NSLog(@"concurrent_queue1");
//    });
//    
//    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        NSLog(@"return main queue");
//    });

//    /**
//     *  dispatch_group_wait给定一个时间，如果在等待时间结束前group所有任务执行完毕则返回0，否则返回非0，这个函数是一个同步任务
//     */
//    dispatch_group_async(group, serial_queue, ^{
//        sleep(3);
//        NSLog(@"serial_queue1");
//    });
//    dispatch_group_async(group, serial_queue, ^{
//        sleep(2);
//        NSLog(@"serial_queue2");
//    });
//    dispatch_group_async(group, concurrent_queue, ^{
//        sleep(3);
//        NSLog(@"concurrent_queue1");
//    });
//
//    long i = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 6));
//    NSLog(@"-- %ld --",i);
//    dispatch_group_async(group, concurrent_queue, ^{
//        NSLog(@"finish all");
//    });
    
    
    /**
     *  使用dispatch_group_enter和dispatch_group_leave添加组任务,两者必须要成对出现
     */
    dispatch_group_enter(group);
    sleep(2);
    NSLog(@"1");
    dispatch_group_leave(group);
    
    dispatch_group_enter(group);
    dispatch_async(concurrent_queue, ^{
        sleep(3);
        NSLog(@"2");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    sleep(2);
    NSLog(@"3");
    dispatch_group_leave(group);
    
    long i = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 6));
    NSLog(@"-- %ld --",i);
    dispatch_group_async(group, concurrent_queue, ^{
        NSLog(@"finish all");
    });

    
}


//dispatch_after定时是指定时派发任务，而不是定时执行。
- (void)dispatchAfter {
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3);
    
    dispatch_after(time, dispatch_get_main_queue(), ^{
        NSLog(@"-- 3s 后 --");
    });
}

//队列和任务
- (void)queue {
    
    /**
     *  串行队列中的任务会等待正在执行的任务执行结束，排队执行
     */
    dispatch_queue_t serial_queue = dispatch_queue_create("serial.queue", DISPATCH_QUEUE_SERIAL);
    //主队列
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    /**
     *  并行，不等待正在执行的任务的处理结果，可以并发执行多个任务
     */
    dispatch_queue_t concurrent_queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    
    //全局队列
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(serial_queue, ^{
        
        NSLog(@"jump to serial queue1");
        dispatch_async(mainQueue, ^{
            NSLog(@"return main queue1");
        });
        
    });
    
    dispatch_sync(concurrent_queue, ^{
        NSLog(@"jump to concurrent queue2");
        dispatch_async(globalQueue, ^{
            NSLog(@"return main queue2");
        });
        
    });
    
}


//在并行队列中，在当前队列调用dispatch_sync，并传入当前队列执行，并不会造成deadlock。dispatch_sync会阻塞当前线程，但是由于队列是并行执行，所以block中的任务会马上执行后返回。
- (void)syncAndConcurrentQueue {
    dispatch_queue_t queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_sync(queue, ^{
        
        NSLog(@"Jump to concurrent.queue! ,thread:%@",[NSThread currentThread]);

        dispatch_sync(queue, ^{
            sleep(3);
            NSLog(@"success6 ,thread:%@",[NSThread currentThread]);
        });
         NSLog(@"return");
    });
}


//在串行队列中，在当前队列调用dispatch_sync，并传入当前队列执行，会造成deadlock。 dispatch_sync会阻塞当前线程，等待block中的任务执行完之后再继续执行，但是由于队列是串行执行，block中的任务放在最后，所以永远没有机会执行，线程死锁
- (void)synAndSerialQueue {
    
    dispatch_queue_t queue = dispatch_queue_create("serial.queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"Jump to serial.queue!");
        
        dispatch_sync(queue, ^{
            NSLog(@"success");
        });
        NSLog(@"return");
    });
}

//任务1会阻塞主线程，直到block中执行完毕返回，任务二在主线程添加了了一个同步任务，阻塞当前线程，知道任务执行完毕返回，而任务2没有机会被执行。造成两条线程死锁。
- (void)recycle {
    
    dispatch_queue_t concurrent_queue = dispatch_queue_create("concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    
    //任务1
    dispatch_sync(concurrent_queue, ^{
        
        NSLog(@"jump to concurrent queue");
        
        //任务2
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            NSLog(@"return main queue");
        });
        
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
