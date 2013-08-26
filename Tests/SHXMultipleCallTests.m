//
//  SHXMultipleCallTests.m
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

#import "SHXMultipleCallTests.h"

DoneCallback (^callbackAggregator)(NSUInteger times, DoneCallback ultimateCallback) = ^(NSUInteger times, DoneCallback ultimateCallback) {
    __block NSUInteger soFarCalled = 0;
    return ^() {
        soFarCalled += 1;
        if (soFarCalled == times) {
            ultimateCallback();
        }
    };
};

@implementation SHXMultipleCallTests

- (void)testMultipleFulfilledHandlers {
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    
    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSUInteger counter = 0;
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            counter += 1;
            return value;
        }];
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            counter += 1;
            return value;
        }];
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            counter += 1;
            return value;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STFail(@"must not be called");
            return reason;
        }];
        
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            STAssertTrue(3 == counter, @"must be called 3 times");
            
            callback();
            return value;
        }];
    }];
}

- (void)testMultipleFulfilledHandlersOneOfWhichReturnsAnError {
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSUInteger counter = 0;
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            counter += 1;
            return value;
        }];
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            counter += 1;
            return reason;
        }];
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            counter += 1;
            return value;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STFail(@"must not be called");
            return reason;
        }];
        
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            STAssertTrue(3 == counter, @"must be called 3 times");
            
            callback();
            return value;
        }];
    }];
}

- (void)testMultipleFulfilledHandlersResultingInMultipleBranches {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    NSError *sentinel2 = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSDictionary *sentinel3 = @{ @"sentinel3": @"sentinel3" };
    
    [self checkFulfilledPromiseWithValue:dummy testBlock:^(SHXPromise *promise, DoneCallback callback) {
        DoneCallback semiDoneCallback = callbackAggregator(3, callback);
        
        [[promise setOnFulfilled:^id(id value) {
            return sentinel;
        }] setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            semiDoneCallback();
            return value;
        }];
        
        [[promise setOnFulfilled:^id(id value) {
            return sentinel2;
        }] setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel2, @"must be equal");
            semiDoneCallback();
            return reason;
        }];
        
        [[promise setOnFulfilled:^id(id value) {
            return sentinel3;
        }] setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel3, @"must be equal");
            semiDoneCallback();
            return value;
        }];
    }];
}

- (void)testMultipleFulfilledHandlersAreCalledInTheOriginalOrder {
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    
    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSDate *firstCalled;
        __block NSDate *secondCalled;
        __block NSDate *thirdCalled;
        
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            firstCalled = [NSDate date];
            return value;
        }];
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            secondCalled = [NSDate date];
            return value;
        }];
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            thirdCalled = [NSDate date];
            return value;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STFail(@"must not be called");
            return reason;
        }];
        
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            STAssertEquals([firstCalled compare:secondCalled], NSOrderedAscending, @"first fulfilled block must be called first");
            STAssertEquals([secondCalled compare:thirdCalled], NSOrderedAscending, @"second fulfilled block must be called first");
            
            callback();
            return value;
        }];
    }];
    
    [self checkFulfilledPromiseWithValue:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSDate *firstCalled;
        __block NSDate *secondCalled;
        __block NSDate *thirdCalled;
        
        __weak SHXPromise *weakPromise = promise;
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            firstCalled = [NSDate date];
            [weakPromise setOnFulfilled:^id(id value) {
                STAssertEquals(value, sentinel, @"must be equal");
                thirdCalled = [NSDate date];
                return value;
            }];
            return value;
        }];
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            secondCalled = [NSDate date];
            return value;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STFail(@"must not be called");
            return reason;
        }];
        
        [promise setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                STAssertEquals([firstCalled compare:secondCalled], NSOrderedAscending, @"first fulfilled block must be called first");
                STAssertEquals([secondCalled compare:thirdCalled], NSOrderedAscending, @"second fulfilled block must be called first");
                callback();
            });
            
            return value;
        }];
    }];
}

- (void)testMultipleRejectedHandlers {
    NSError *sentinel = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    
    [self checkRejectedPromiseWithReason:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSUInteger counter = 0;
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            counter += 1;
            return dummy;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            counter += 1;
            return dummy;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            counter += 1;
            return dummy;
        }];
        [promise setOnFulfilled:^id(id value) {
            STFail(@"must not be called");
            return value;
        }];
        
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            STAssertTrue(3 == counter, @"must be called 3 times");
            
            callback();
            return reason;
        }];
    }];
}

- (void)testMultipleRejectedHandlersOneOfWhichReturnsAnError {
    NSError *sentinel = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSDictionary *dummy = @{ @"dummy": @"dummy" };
    
    [self checkRejectedPromiseWithReason:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSUInteger counter = 0;
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            counter += 1;
            return dummy;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            counter += 1;
            return reason;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            counter += 1;
            return dummy;
        }];
        [promise setOnFulfilled:^id(id value) {
            STFail(@"must not be called");
            return value;
        }];
        
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            STAssertTrue(3 == counter, @"must be called 3 times");
            
            callback();
            return reason;
        }];
    }];
}

- (void)testMultipleRejectedHandlersResultingInMultipleBranches {
    NSError *dummy = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSDictionary *sentinel = @{ @"sentinel": @"sentinel" };
    NSError *sentinel2 = [NSError errorWithDomain:@"SHXTest" code:2 userInfo:@{}];
    NSDictionary *sentinel3 = @{ @"sentinel3": @"sentinel3" };
    
    [self checkRejectedPromiseWithReason:dummy testBlock:^(SHXPromise *promise, DoneCallback callback) {
        DoneCallback semiDoneCallback = callbackAggregator(3, callback);
        
        [[promise setOnRejected:^id(NSError *reason) {
            return sentinel;
        }] setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel, @"must be equal");
            semiDoneCallback();
            return value;
        }];
        
        [[promise setOnRejected:^id(NSError *reason) {
            return sentinel2;
        }] setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel2, @"must be equal");
            semiDoneCallback();
            return reason;
        }];
        
        [[promise setOnRejected:^id(NSError *reason) {
            return sentinel3;
        }] setOnFulfilled:^id(id value) {
            STAssertEquals(value, sentinel3, @"must be equal");
            semiDoneCallback();
            return value;
        }];
    }];
}

- (void)testMultipleRejectedHandlersAreCalledInTheOriginalOrder {
    NSError *sentinel = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    [self checkRejectedPromiseWithReason:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSDate *firstCalled;
        __block NSDate *secondCalled;
        __block NSDate *thirdCalled;
        
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            firstCalled = [NSDate date];
            return reason;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            secondCalled = [NSDate date];
            return reason;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            thirdCalled = [NSDate date];
            return reason;
        }];
        [promise setOnFulfilled:^id(id value) {
            STFail(@"must not be called");
            return value;
        }];
        
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            STAssertEquals([firstCalled compare:secondCalled], NSOrderedAscending, @"first fulfilled block must be called first");
            STAssertEquals([secondCalled compare:thirdCalled], NSOrderedAscending, @"second fulfilled block must be called first");
            
            callback();
            return reason;
        }];
    }];
    
    [self checkRejectedPromiseWithReason:sentinel testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block NSDate *firstCalled;
        __block NSDate *secondCalled;
        __block NSDate *thirdCalled;
        
        __weak SHXPromise *weakPromise = promise;
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            firstCalled = [NSDate date];
            [weakPromise setOnRejected:^id(NSError *reason) {
                STAssertEquals(reason, sentinel, @"must be equal");
                thirdCalled = [NSDate date];
                return reason;
            }];
            return reason;
        }];
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            secondCalled = [NSDate date];
            return reason;
        }];
        [promise setOnFulfilled:^id(id value) {
            STFail(@"must not be called");
            return value;
        }];
        
        [promise setOnRejected:^id(NSError *reason) {
            STAssertEquals(reason, sentinel, @"must be equal");
            
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                STAssertEquals([firstCalled compare:secondCalled], NSOrderedAscending, @"first fulfilled block must be called first");
                STAssertEquals([secondCalled compare:thirdCalled], NSOrderedAscending, @"second fulfilled block must be called first");
                callback();
            });
            
            return reason;
        }];
    }];
}

@end
