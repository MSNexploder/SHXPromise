//
//  SHXRejectionTests.m
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

#import "SHXRejectionTests.h"

@implementation SHXRejectionTests

- (void)testIfRejectedIsCalledWithRightValue {
    NSError *sentinel = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    [self checkRejectedPromiseWithReason:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        [promise onRejected:^id(NSError *reason) {
            STAssertEqualObjects(reason, sentinel, @"must be called with reason");
            callback();
            return reason;
        }];
    }];
}

- (void)testIfRejectedIsNotCalledMoreThanOnce {
    NSError *dummy = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    __block int timesCalled = 0;
    __block BOOL alreadyRejectedDone = NO;
    [[self rejectedPromiseWithReason:dummy] onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyRejectedDone = YES;
        return reason;
    }];
    POLL(alreadyRejectedDone);
}

- (void)testIfRejectedIsNotCalledMoreThanOnceImmediately {
    NSError *dummy = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled = 0;
    __block BOOL alreadyRejectedDone = NO;
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyRejectedDone = YES;
        return reason;
    }];
    [promise reject:dummy];
    [promise reject:dummy];
    POLL(alreadyRejectedDone);
}

- (void)testIfRejectedIsNotCalledMoreThanOnceDelayed {
    NSError *dummy = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled = 0;
    __block BOOL alreadyRejectedDone = NO;
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyRejectedDone = YES;
        return reason;
    }];
    
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise reject:dummy];
        [promise reject:dummy];
    });
    POLL(alreadyRejectedDone);
}

- (void)testIfRejectedIsNotCalledMoreThanOnceImmediatelyAndDelayed {
    NSError *dummy = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled = 0;
    __block BOOL alreadyRejectedDone = NO;
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyRejectedDone = YES;
        return reason;
    }];
    [promise reject:dummy];
    
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise reject:dummy];
    });
    POLL(alreadyRejectedDone);
}

- (void)testMultipleRejectedCallsSpacedApartInTime {
    NSError *dummy = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled1 = 0;
    __block int timesCalled2 = 0;
    __block int timesCalled3 = 0;
    
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled1, 1, @"must not be called more than once");
        return reason;
    }];
    
    NSDate *untilDate1 = [NSDate dateWithTimeIntervalSinceNow:0.05f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate1];
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled2, 1, @"must not be called more than once");
        return reason;
    }];
    
    NSDate *untilDate2 = [NSDate dateWithTimeIntervalSinceNow:0.05f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate2];
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled3, 1, @"must not be called more than once");
        return reason;
    }];
    
    NSDate *untilDate3 = [NSDate dateWithTimeIntervalSinceNow:0.05f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate3];
    [promise reject:dummy];
}

- (void)testMultipleRejectedCallsInterleavedWithRejection {
    NSError *dummy = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled1 = 0;
    __block int timesCalled2 = 0;
    
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled1, 1, @"must not be called more than once");
        return reason;
    }];
    
    [promise reject:dummy];
    
    [promise onRejected:^id(NSError *reason) {
        STAssertEquals(++timesCalled2, 1, @"must not be called more than once");
        return reason;
    }];
}

- (void)testRejectedIsNotCalledIfFulfilled {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    
    [self checkFulfilledPromiseWithValue:dummy testBlock:^(SHXPromise *promise, DoneCallback callback) {
        [promise onRejected:^id(NSError *reason) {
            STAssertFalse(YES, @"must not be called");
            callback();
            return reason;
        }];
        
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            callback();
        });
    }];
}

- (void)testRejectedIsNotCalledOnFulfillmentThenRejectedImmediately {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise onRejected:^id(NSError *reason) {
        STAssertFalse(YES, @"must not be called");
        return reason;
    }];
    [promise fulfill:dummy];
    [promise reject:reason];
    
    NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:0.2f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
}

- (void)testRejectedIsNotCalledOnFulfillmentThenRejectDelayed {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise onRejected:^id(NSError *reason) {
        STAssertFalse(YES, @"must not be called");
        return reason;
    }];
    
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise fulfill:dummy];
        [promise reject:reason];
    });
    
    NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:0.2f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
}

- (void)testRejectedIsNotCalledOnFulfilledImmediatelyThenRejectDelayed {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise onRejected:^id(NSError *reason) {
        STAssertFalse(YES, @"must not be called");
        return reason;
    }];
    
    [promise fulfill:dummy];
    
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise reject:reason];
    });
    
    NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:0.2f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
}

@end
