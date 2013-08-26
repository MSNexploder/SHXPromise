//
//  SHXFulfillmentTests.m
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

#import "SHXFulfillmentTests.h"

@implementation SHXFulfillmentTests

- (void)testIfFulfilledIsCalledWithRightValue {
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };

    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        [promise onFulfilled:^id(id value) {
            STAssertEqualObjects(value, sentinel, @"must be called with fulfillment value");
            callback();
            return value;
        }];
    }];
}

- (void)testIfFulfilledIsNotCalledMoreThanOnce {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };

    __block int timesCalled = 0;
    __block BOOL alreadyFulfilledDone = NO;
    [[self fulfilledPromiseWithValue:dummy] onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyFulfilledDone = YES;
        return value;
    }];
    POLL(alreadyFulfilledDone);
}

- (void)testIfFulfilledIsNotCalledMoreThanOnceImmediately {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };

    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled = 0;
    __block BOOL alreadyFulfilledDone = NO;
    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyFulfilledDone = YES;
        return value;
    }];
    [promise fulfill:dummy];
    [promise fulfill:dummy];
    POLL(alreadyFulfilledDone);
}

- (void)testIfFulfilledIsNotCalledMoreThanOnceDelayed {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled = 0;
    __block BOOL alreadyFulfilledDone = NO;
    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyFulfilledDone = YES;
        return value;
    }];
    
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise fulfill:dummy];
        [promise fulfill:dummy];

    });
    POLL(alreadyFulfilledDone);
}

- (void)testIfFulfilledIsNotCalledMoreThanOnceImmediatelyAndDelayed {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled = 0;
    __block BOOL alreadyFulfilledDone = NO;
    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled, 1, @"must not be called more than once");
        alreadyFulfilledDone = YES;
        return value;
    }];
    [promise fulfill:dummy];
    
    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise fulfill:dummy];
    });
    POLL(alreadyFulfilledDone);
}

- (void)testMultipleFulfilledCallsSpacedApartInTime {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };

    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled1 = 0;
    __block int timesCalled2 = 0;
    __block int timesCalled3 = 0;

    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled1, 1, @"must not be called more than once");
        return value;
    }];

    NSDate *untilDate1 = [NSDate dateWithTimeIntervalSinceNow:0.05f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate1];
    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled2, 1, @"must not be called more than once");
        return value;
    }];

    NSDate *untilDate2 = [NSDate dateWithTimeIntervalSinceNow:0.05f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate2];
    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled3, 1, @"must not be called more than once");
        return value;
    }];

    NSDate *untilDate3 = [NSDate dateWithTimeIntervalSinceNow:0.05f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate3];
    [promise fulfill:dummy];
}

- (void)testMultipleFulfilledCallsInterleavedWithFulfillment {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    __block int timesCalled1 = 0;
    __block int timesCalled2 = 0;
    
    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled1, 1, @"must not be called more than once");
        return value;
    }];

    [promise fulfill:dummy];

    [promise onFulfilled:^id(id value) {
        STAssertEquals(++timesCalled2, 1, @"must not be called more than once");
        return value;
    }];
}

- (void)testFulfilledIsNotCalledIfRejected {
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];

    [self checkRejectedPromiseWithReason:reason testBlock:^(SHXPromise *promise, DoneCallback callback) {
        [promise onFulfilled:^id(id value) {
            STAssertFalse(YES, @"must not be called");
            callback();
            return value;
        }];

        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            callback();
        });
    }];
}

- (void)testFulfilledIsNotCalledOnRejectThenFulfillImmediately {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];

    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise onFulfilled:^id(id value) {
        STAssertFalse(YES, @"must not be called");
        return value;
    }];
    [promise reject:reason];
    [promise fulfill:dummy];
    
    NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:0.2f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
}

- (void)testFulfilledIsNotCalledOnRejectThenFulfillDelayed {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise onFulfilled:^id(id value) {
        STAssertFalse(YES, @"must not be called");
        return value;
    }];

    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise reject:reason];
        [promise fulfill:dummy];
    });
    
    NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:0.2f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
}

- (void)testFulfilledIsNotCalledOnRejectImmediatelyThenFulfillDelayed {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    SHXPromise *promise = [[SHXPromise alloc] init];
    [promise onFulfilled:^id(id value) {
        STAssertFalse(YES, @"must not be called");
        return value;
    }];

    [promise reject:reason];

    double delayInSeconds = 0.1f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [promise fulfill:dummy];
    });
    
    NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:0.2f];
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate];
}

@end
