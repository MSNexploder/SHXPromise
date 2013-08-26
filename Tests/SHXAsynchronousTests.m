//
//  SHXAsynchronousTests.m
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

#import "SHXAsynchronousTests.h"

@implementation SHXAsynchronousTests

- (void)testOnFulfilledMustReturnBeforeCallbackIsCalled {
    NSDictionary *dummy = @{ @"dummy": @"dummy" };

    [self checkFulfilledPromiseWithValue:dummy testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block BOOL hasReturned = NO;
        [promise onFulfilled:^id(id value) {
            STAssertTrue(hasReturned, @"must be called after onFulfilled returned");
            callback();
            return value;
        }];
        hasReturned = YES;
    }];
}

- (void)testOnRejectedMustReturnBeforeCallbackIsCalled {
    NSError *reason = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    
    [self checkRejectedPromiseWithReason:reason testBlock:^(SHXPromise *promise, DoneCallback callback) {
        __block BOOL hasReturned = NO;
        [promise onRejected:^id(NSError *reason) {
            STAssertTrue(hasReturned, @"must be called after onRejected returned");
            callback();
            return reason;
        }];
        hasReturned = YES;
    }];
}

@end
