//
//  SHXTestBase.m
//
// Copyright (c) 2013 Stefan Huber
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SHXTestBase.h"

@implementation SHXTestBase

- (void)checkFulfilledPromiseWithValue:(id)value testBlock:(TestCallback)test {
    // already-fulfilled
    __block BOOL alreadyFulfilledDone = NO;
    SHXPromise *alreadyFulfilledPromise = [self fulfilledPromiseWithValue:value];
    test(alreadyFulfilledPromise, ^() {
        alreadyFulfilledDone = YES;
    });
    POLL(alreadyFulfilledDone);
    
    // immediately-fulfilled
    __block BOOL immediatelyFulfilledDone = NO;
    SHXPromise *immediatelyFulfilledPromise = [[SHXPromise alloc] init];
    test(immediatelyFulfilledPromise, ^() {
        immediatelyFulfilledDone = YES;
    });
    [immediatelyFulfilledPromise fulfill:value];
    POLL(immediatelyFulfilledDone);
    
    // eventually-fulfilled
    __block BOOL eventuallyFulfilledDone = NO;
    SHXPromise *eventuallyFulfilledPromise = [[SHXPromise alloc] init];
    test(eventuallyFulfilledPromise, ^() {
        eventuallyFulfilledDone = YES;
    });
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [eventuallyFulfilledPromise fulfill:value];
    });
    POLL(immediatelyFulfilledDone);
}

- (void)checkRejectedPromiseWithReason:(NSError *)reason testBlock:(TestCallback)test {
    // already-rejected
    __block BOOL alreadyRejectedDone = NO;
    SHXPromise *alreadyRejectedPromise = [self rejectedPromiseWithReason:reason];
    test(alreadyRejectedPromise, ^() {
        alreadyRejectedDone = YES;
    });
    POLL(alreadyRejectedDone);
    
    // immediately-rejected
    __block BOOL immediatelyRejectedDone = NO;
    SHXPromise *immediatelyRejectedPromise = [[SHXPromise alloc] init];
    test(immediatelyRejectedPromise, ^() {
        immediatelyRejectedDone = YES;
    });
    [immediatelyRejectedPromise reject:reason];
    POLL(immediatelyRejectedDone);
    
    // eventually-rejected
    __block BOOL eventuallyRejectedDone = NO;
    SHXPromise *eventuallyRejectedPromise = [[SHXPromise alloc] init];
    test(eventuallyRejectedPromise, ^() {
        eventuallyRejectedDone = YES;
    });
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [eventuallyRejectedPromise reject:reason];
    });
    POLL(immediatelyRejectedDone);
}

- (SHXPromise *)fulfilledPromiseWithValue:(id)value {
    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise fulfill:value];
    return promise;
}

- (SHXPromise *)rejectedPromiseWithReason:(NSError *)reason {
    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise reject:reason];
    return promise;
}

@end
