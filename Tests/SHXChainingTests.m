//
//  SHXChainingTests.m
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

#import "SHXChainingTests.h"

@implementation SHXChainingTests

- (void)testSetFulfilledMustReturnAPromise {
    SHXPromise *promise1 = [[SHXPromise alloc] init];
    SHXPromise *promise2 = [promise1 onFulfilled:^id(id value) { return value; }];
    
    STAssertEquals([promise2 class], [SHXPromise class], @"must be a promise");
    STAssertNotNil(promise2, @"must not be null");
}

- (void)testSetRejectedMustReturnAPromise {
    SHXPromise *promise1 = [[SHXPromise alloc] init];
    SHXPromise *promise2 = [promise1 onRejected:^id(NSError *reason) { return reason; }];
    
    STAssertEquals([promise2 class], [SHXPromise class], @"must be a promise");
    STAssertNotNil(promise2, @"must not be null");
}

- (void)testSetFulfilledAndRejectedMustReturnAPromise {
    SHXPromise *promise1 = [[SHXPromise alloc] init];
    SHXPromise *promise2 = [promise1 onFulfilled:^id(id value) { return value; } rejected:^id(NSError *reason) { return reason; }];
    
    STAssertEquals([promise2 class], [SHXPromise class], @"must be a promise");
    STAssertNotNil(promise2, @"must not be null");
}

- (void)testReturnedValueMustBeUsedToFulfillSuccessivePromise {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *dummyError = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    void (^testValue)(id value) = ^(id expectedValue) {
        [self checkFulfilledPromiseWithValue:dummy testBlock:^(SHXPromise *promise, DoneCallback callback) {
            SHXPromise *promise2 = [promise onFulfilled:^id(id value) {
                return expectedValue;
            }];
            [promise2 onFulfilled:^id(id value) {
                STAssertEquals(value, expectedValue, @"must be equal");
                callback();
                return value;
            }];
        }];
        [self checkRejectedPromiseWithReason:dummyError testBlock:^(SHXPromise *promise, DoneCallback callback) {
            SHXPromise *promise2 = [promise onRejected:^id(NSError *reason) {
                return expectedValue;
            }];
            [promise2 onFulfilled:^id(id value) {
                STAssertEquals(value, expectedValue, @"must be equal");
                callback();
                return value;
            }];
        }];
    };
    
    testValue(@(false));
    testValue(@(1));
    testValue(@(2.0f));
    testValue([[NSObject alloc] init]);
}

- (void)testReturnedErrorMustBeUsedToRejectSuccessivePromise {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *dummyError = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSError *expectedReason = [NSError errorWithDomain:@"SHXTest" code:2 userInfo:@{}];
    
    [self checkFulfilledPromiseWithValue:dummy testBlock:^(SHXPromise *promise, DoneCallback callback) {
        SHXPromise *promise2 = [promise onFulfilled:^id(id value) {
            return expectedReason;
        }];
        [promise2 onRejected:^id(NSError *reason) {
            STAssertEquals(reason, expectedReason, @"must be equal");
            callback();
            return reason;
        }];
    }];
    [self checkRejectedPromiseWithReason:dummyError testBlock:^(SHXPromise *promise, DoneCallback callback) {
        SHXPromise *promise2 = [promise onRejected:^id(NSError *reason) {
            return expectedReason;
        }];
        [promise2 onRejected:^id(NSError *reason) {
            STAssertEquals(reason, expectedReason, @"must be equal");
            callback();
            return reason;
        }];
    }];
}

- (void)testSuccessivePromiseMustRemainPendingUntilReturnedPromiseIsFulfilledOrRejected {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSError *dummyError = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    [self checkFulfilledPromiseWithValue:dummy testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block BOOL wasFulfilled = NO;
        __block BOOL wasRejected = NO;
        
        SHXPromise *promise2 = [promise onFulfilled:^id(id value) {
            return [[SHXPromise alloc] init];
        }];
        
        [promise2 onFulfilled:^id(id value) {
            wasFulfilled = YES;
            return value;
        } rejected:^id(NSError *reason) {
            wasRejected = YES;
            return reason;
        }];
        
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            STAssertFalse(wasFulfilled, @"must not be fulfilled");
            STAssertFalse(wasRejected, @"must not be rejected");
            callback();
        });
    }];
    
    [self checkRejectedPromiseWithReason:dummyError testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block BOOL wasFulfilled = NO;
        __block BOOL wasRejected = NO;
        
        SHXPromise *promise2 = [promise onRejected:^id(NSError *reason) {
            return [[SHXPromise alloc] init];
        }];
        
        [promise2 onFulfilled:^id(id value) {
            wasFulfilled = YES;
            return value;
        } rejected:^id(NSError *reason) {
            wasRejected = YES;
            return reason;
        }];
        
        double delayInSeconds = 0.1f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            STAssertFalse(wasFulfilled, @"must not be fulfilled");
            STAssertFalse(wasRejected, @"must not be rejected");
            callback();
        });
    }];
}

- (void)testSuccessivePromiseMustBeFulfilledWithTheValueOfTheReturnedPromise {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    NSError *sentinelError = [NSError errorWithDomain:@"SHXTest" code:2 userInfo:@{}];
    
    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        SHXPromise *promise1 = [self fulfilledPromiseWithValue:dummy];
        SHXPromise *promise2 = [promise1 onFulfilled:^id(id value) {
            return promise;
        }];
        
        [promise2 onFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            callback();
            return value;
        }];
    }];
    
    [self checkRejectedPromiseWithReason:sentinelError testBlock:^(SHXPromise *promise, DoneCallback callback) {
        SHXPromise *promise1 = [self fulfilledPromiseWithValue:dummy];
        SHXPromise *promise2 = [promise1 onFulfilled:^id(id value) {
            return promise;
        }];
        
        [promise2 onRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinelError, @"must be equal");
            callback();
            return reason;
        }];
    }];
}

- (void)testSuccessivePromiseMustBeRejectedWithTheReasonOfTheReturnedPromise {
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    NSError *dummyError = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSError *sentinelError = [NSError errorWithDomain:@"SHXTest" code:2 userInfo:@{}];
    
    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        SHXPromise *promise1 = [self rejectedPromiseWithReason:dummyError];
        SHXPromise *promise2 = [promise1 onRejected:^id(NSError *reason) {
            return promise;
        }];
        
        [promise2 onFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            callback();
            return value;
        }];
    }];
    
    [self checkRejectedPromiseWithReason:sentinelError testBlock:^(SHXPromise *promise, DoneCallback callback) {
        SHXPromise *promise1 = [self rejectedPromiseWithReason:dummyError];
        SHXPromise *promise2 = [promise1 onRejected:^id(NSError *reason) {
            return promise;
        }];
        
        [promise2 onRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinelError, @"must be equal");
            callback();
            return reason;
        }];
    }];
}

- (void)testFulfilledPropagateOverSeveralLevels {
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    
    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        [[promise onRejected:^id(NSError *reason) {
            STFail(@"must not be called");
            return reason;
        }] onFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            callback();
            return value;
        }];
    }];
}

- (void)testRejectedPropagateOverSeveralLevels {
    NSError *sentinel = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    [self checkRejectedPromiseWithReason:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        [[promise onFulfilled:^id(id value) {
            STFail(@"must not be called");
            return value;
        }] onRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            callback();
            return reason;
        }];
    }];
}

@end
