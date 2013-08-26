//
//  SHXJoinedTests.m
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

#import "SHXJoinedTests.h"

@implementation SHXJoinedTests

- (void)testAllJoinedAllFulfilled {
    NSDictionary *sentinel1 = @{ @"sentinel": @"sentinel" };
    NSDictionary *sentinel2 = @{ @"sentinel2": @"sentinel2" };
    NSDictionary *sentinel3 = @{ @"sentinel3": @"sentinel3" };
    __block BOOL done = NO;
    
    SHXPromise *promise1 = [[SHXPromise alloc] init];
    SHXPromise *promise2 = [[SHXPromise alloc] init];
    SHXPromise *promise3 = [[SHXPromise alloc] init];
    
    [[SHXPromise all:@[promise1, promise2, promise3]] onFulfilled:^id(id value) {
        NSArray *expected = @[sentinel1, sentinel2, sentinel3];
        STAssertEqualObjects(value, expected, @"must be equal");
        done = YES;
        return value;
    } rejected:^id(NSError *reason) {
        STFail(@"must not be called");
        return reason;
    }];
    
    [promise1 fulfill:sentinel1];
    [promise2 fulfill:sentinel2];
    [promise3 fulfill:sentinel3];
    
    POLL(done);
}

- (void)testAllJoinedOneRejected {
    NSDictionary *sentinel1 = @{ @"sentinel": @"sentinel" };
    NSError *sentinel2 = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSDictionary *sentinel3 = @{ @"sentinel3": @"sentinel3" };
    __block BOOL done = NO;
    
    SHXPromise *promise1 = [[SHXPromise alloc] init];
    SHXPromise *promise2 = [[SHXPromise alloc] init];
    SHXPromise *promise3 = [[SHXPromise alloc] init];
    
    [[SHXPromise all:@[promise1, promise2, promise3]] onFulfilled:^id(id value) {
        STFail(@"must not be called");
        return value;
    } rejected:^id(NSError *reason) {
        STAssertEqualObjects(reason, sentinel2, @"must be equal");
        done = YES;
        return reason;
    }];
    
    [promise1 fulfill:sentinel1];
    [promise2 reject:sentinel2];
    [promise3 fulfill:sentinel3];
    
    POLL(done);
}

- (void)testAllJoinedMultipleRejected {
    NSDictionary *sentinel1 = @{ @"sentinel": @"sentinel" };
    NSError *sentinel2 = [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
    NSError *sentinel3 = [NSError errorWithDomain:@"SHXTest" code:2 userInfo:@{}];
    __block BOOL done = NO;
    
    SHXPromise *promise1 = [[SHXPromise alloc] init];
    SHXPromise *promise2 = [[SHXPromise alloc] init];
    SHXPromise *promise3 = [[SHXPromise alloc] init];
    
    [[SHXPromise all:@[promise1, promise2, promise3]] onFulfilled:^id(id value) {
        STFail(@"must not be called");
        return value;
    } rejected:^id(NSError *reason) {
        STAssertEqualObjects(reason, sentinel2, @"must be equal");
        done = YES;
        return reason;
    }];
    
    [promise1 fulfill:sentinel1];
    [promise2 reject:sentinel2];
    [promise3 reject:sentinel3];
    
    POLL(done);
}

@end
