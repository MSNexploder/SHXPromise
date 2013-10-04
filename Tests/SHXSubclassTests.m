//
//  SHXSubclassTests.m
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

#import "SHXSubclassTests.h"

@interface SHXSubclassPromise : SHXPromise

@property (nonatomic, strong, readwrite) NSString *additionalString;
@property (nonatomic, readwrite) CGFloat additionalFloat;

@end

@implementation SHXSubclassPromise

+ (NSArray *)additionalPropertyKeys {
    return @[@"additionalString", @"additionalFloat"];
}

@end

@implementation SHXSubclassTests

- (void)testSetAdditionalSubclassProperties {
    SHXSubclassPromise *promise1 = [[SHXSubclassPromise alloc] init];
    [promise1 setAdditionalString:@"string"];
    [promise1 setAdditionalFloat:123.0f];
    SHXSubclassPromise *promise2 = [promise1 onFulfilled:^id(id value) { return value; }];
    
    STAssertEquals([promise2 class], [promise1 class], @"must be the same class");
    STAssertEquals([promise2 additionalString], [promise1 additionalString], @"must be a equal");
    STAssertEquals([promise2 additionalFloat], [promise1 additionalFloat], @"must be a equal");
}

@end
