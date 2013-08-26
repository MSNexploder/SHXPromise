//
//  SHXTestBase.h
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

#import <SenTestingKit/SenTestingKit.h>

#import "SHXPromise.h"

#define POLL_INTERVAL 0.05
#define N_SEC_TO_POLL 1.0
#define MAX_POLL_COUNT N_SEC_TO_POLL / POLL_INTERVAL

#define CAT(x, y) x ## y
#define TOKCAT(x, y) CAT(x, y)
#define __pollCountVar TOKCAT(__pollCount,__LINE__)

#define POLL(__done) \
NSUInteger __pollCountVar = 0; \
while (__done == NO && __pollCountVar  < MAX_POLL_COUNT) { \
    NSDate *untilDate = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL]; \
    [[NSRunLoop currentRunLoop] runUntilDate:untilDate]; \
    __pollCountVar ++; \
} \
if (__pollCountVar  == MAX_POLL_COUNT) { \
    STFail(@"polling timed out"); \
}

typedef void(^DoneCallback)();
typedef void(^TestCallback)(SHXPromise *promise, DoneCallback callback);

@interface SHXTestBase : SenTestCase

- (void)checkFulfilledPromiseWithValue:(id)value testBlock:(TestCallback)test;
- (void)checkRejectedPromiseWithReason:(NSError *)reason testBlock:(TestCallback)test;

- (SHXPromise *)fulfilledPromiseWithValue:(id)value;
- (SHXPromise *)rejectedPromiseWithReason:(NSError *)reason;

@end
