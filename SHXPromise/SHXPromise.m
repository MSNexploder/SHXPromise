//
//  SHXPromise.m
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

#import "SHXPromise.h"

typedef NS_ENUM(NSInteger, SHXPromiseState) {
    SHXPromiseStatePending,
    SHXPromiseStateRejected,
    SHXPromiseStateFulfilled
};

@interface SHXPromiseCallback : NSObject

@property (nonatomic, strong, readonly) SHXPromise *promise;
@property (nonatomic, strong, readonly) id callback;
@property (nonatomic, readonly) dispatch_queue_t queue;

- (instancetype)initWithPromise:(SHXPromise *)promise callback:(id)callback queue:(dispatch_queue_t)queue;

@end

@implementation SHXPromiseCallback

- (instancetype)initWithPromise:(SHXPromise *)promise callback:(id)callback queue:(dispatch_queue_t)queue {
    self = [self init];
    if (self != nil) {
        _promise = promise;
        _callback = callback;
        _queue = queue;
    }
    
    return self;
}

@end


@interface SHXPromise ()

@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, strong, readwrite) NSError *reason;
@property (nonatomic, strong, readwrite) NSMutableArray *onFulfilledCallbacks;
@property (nonatomic, strong, readwrite) NSMutableArray *onRejectedCallbacks;
@property (nonatomic, readwrite) SHXPromiseState state;

- (void)callFulfillmentBlock:(FulfillmentBlock)callback promise:(SHXPromise *)promise value:(id)value queue:(dispatch_queue_t)queue;
- (void)callRejectionBlock:(RejectionBlock)callback promise:(SHXPromise *)promise reason:(NSError *)reason queue:(dispatch_queue_t)queue;

@end

static inline void handlePromiseWithValue(SHXPromise *promise, id value) {
    if ([value isKindOfClass:[NSError class]]) {
        [promise reject:(NSError *)value];
    } else if ([value isKindOfClass:[SHXPromise class]]) {
        [(SHXPromise *)value onFulfilled:^id(id value) {
            [promise fulfill:value];
            return value;
        } rejected:^id(NSError *reason) {
            [promise reject:reason];
            return reason;
        }];
    } else {
        [promise fulfill:value];
    }
}

static inline NSString *stringFromPromiseState(SHXPromiseState state) {
    switch (state) {
        case SHXPromiseStatePending:
            return @"pending";
        case SHXPromiseStateFulfilled:
            return @"fulfilled";
        case SHXPromiseStateRejected:
            return @"rejected";
    }
}

@implementation SHXPromise

- (id)init {
    self = [super init];
    if (self != nil) {
        [self setState:SHXPromiseStatePending];
        [self setOnFulfilledCallbacks:[NSMutableArray array]];
        [self setOnRejectedCallbacks:[NSMutableArray array]];
    }
    
    return self;
}

+ (SHXPromise *)all:(NSArray *)promises {
    SHXPromise *finalPromise = [[SHXPromise alloc] init];
    
    NSUInteger count = [promises count];
    __block NSUInteger resolvedCount = 0;
    __block NSMutableArray *resultValue = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++) {
        // initialize array with null - see -testAllJoinedFulfilledOutOfOrder for details
        [resultValue insertObject:[NSNull null] atIndex:i];
    }
    
    NSUInteger counter = 0;
    for (SHXPromise *promise in promises) {
        [promise onFulfilled:^id(id value) {
            @synchronized(finalPromise) {
                if ([finalPromise isFulfilled] || [finalPromise isRejected]) {
                    return value;
                }
                
                resolvedCount += 1;
                [resultValue replaceObjectAtIndex:counter withObject:value];
                
                if (resolvedCount == count) {
                    [finalPromise fulfill:resultValue];
                }
                
                return value;
            }
        } rejected:^id(NSError *reason) {
            @synchronized(finalPromise) {
                if ([finalPromise isFulfilled] || [finalPromise isRejected]) {
                    return reason;
                }
                
                [finalPromise reject:reason];
                return reason;
            }
        }];
        
        counter += 1;
    }
    
    return finalPromise;
}

+ (SHXPromise *)dictionary:(NSDictionary *)promises {
    SHXPromise *finalPromise = [[SHXPromise alloc] init];
    
    NSUInteger count = [promises count];
    __block NSUInteger resolvedCount = 0;
    __block NSMutableDictionary *resultValue = [NSMutableDictionary dictionaryWithCapacity:count];
    
    NSUInteger counter = 0;
    for (id<NSCopying>key in promises) {
        SHXPromise *promise = [promises objectForKey:key];
        [promise onFulfilled:^id(id value) {
            @synchronized(finalPromise) {
                if ([finalPromise isFulfilled] || [finalPromise isRejected]) {
                    return value;
                }
                
                resolvedCount += 1;
                [resultValue setObject:value forKey:key];
                
                if (resolvedCount == count) {
                    [finalPromise fulfill:resultValue];
                }
                
                return value;
            }
        } rejected:^id(NSError *reason) {
            @synchronized(finalPromise) {
                if ([finalPromise isFulfilled] || [finalPromise isRejected]) {
                    return reason;
                }
                
                [finalPromise reject:reason];
                return reason;
            }
        }];
        
        counter += 1;
    }
    
    return finalPromise;
}

+ (NSArray *)additionalPropertyKeys {
    return @[];
}

- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled rejected:(RejectionBlock)onRejected {
    return [self onFulfilled:onFulfilled rejected:onRejected queue:dispatch_get_current_queue()];
}

- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled {
    return [self onFulfilled:onFulfilled queue:dispatch_get_current_queue()];
}

- (instancetype)onRejected:(RejectionBlock)onRejected {
    return [self onRejected:onRejected queue:dispatch_get_current_queue()];
}

- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled rejected:(RejectionBlock)onRejected queue:(dispatch_queue_t)queue {
    onFulfilled = [onFulfilled copy];
    onRejected = [onRejected copy];
    
    SHXPromise *promise = [[[self class] alloc] init];
    for (NSString *key in [[self class] additionalPropertyKeys]) {
        id value = [self valueForKey:key];
        [promise setValue:value forKey:key];
    }
    
    [[self onFulfilledCallbacks] addObject:[[SHXPromiseCallback alloc] initWithPromise:promise callback:onFulfilled queue:queue]];
    [[self onRejectedCallbacks] addObject:[[SHXPromiseCallback alloc] initWithPromise:promise callback:onRejected queue:queue]];
    
    if ([self isFulfilled]) {
        [self callFulfillmentBlock:onFulfilled promise:promise value:[self value] queue:queue];
    }
    if ([self isRejected]) {
        [self callRejectionBlock:onRejected promise:promise reason:[self reason] queue:queue];
    }
    
    return promise;
}

- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled queue:(dispatch_queue_t)queue {
    return [self onFulfilled:onFulfilled rejected:nil queue:queue];
}

- (instancetype)onRejected:(RejectionBlock)onRejected queue:(dispatch_queue_t)queue {
    return [self onFulfilled:nil rejected:onRejected queue:queue];
}

#pragma mark - Properties

- (BOOL)isPending {
    return ([self state] == SHXPromiseStatePending);
}

- (BOOL)isFulfilled {
    return ([self state] == SHXPromiseStateFulfilled);
}

- (BOOL)isRejected {
    return ([self state] == SHXPromiseStateRejected);
}

- (void)fulfill:(id)value {
    @synchronized(self) {
        if ([self state] != SHXPromiseStatePending) {
            return;
        }
        [self setState:SHXPromiseStateFulfilled];
        [self setValue:value];

        for (SHXPromiseCallback *callbackHandler in [self onFulfilledCallbacks]) {
            [self callFulfillmentBlock:[callbackHandler callback] promise:[callbackHandler promise] value:value queue:[callbackHandler queue]];
        }
        
        [self setOnFulfilledCallbacks:nil];
        [self setOnRejectedCallbacks:nil];
    }
}

- (void)resolve:(id)value {
    [self fulfill:value];
}

- (void)reject:(NSError *)reason {
    @synchronized(self) {
        if ([self state] != SHXPromiseStatePending) {
            return;
        }
        [self setReason:reason];
        [self setState:SHXPromiseStateRejected];

        for (SHXPromiseCallback *callbackHandler in [self onRejectedCallbacks]) {
            [self callRejectionBlock:[callbackHandler callback] promise:[callbackHandler promise] reason:reason queue:[callbackHandler queue]];
        }
        
        [self setOnFulfilledCallbacks:nil];
        [self setOnRejectedCallbacks:nil];
    }
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p, state: %@", NSStringFromClass([self class]), self, stringFromPromiseState([self state])];
    switch ([self state]) {
        case SHXPromiseStatePending:
            [description appendString:@">"];
            break;
        case SHXPromiseStateFulfilled:
            [description appendFormat:@", value: %@>", [self value]];
            break;
        case SHXPromiseStateRejected:
            [description appendFormat:@", reason: %@>", [[self reason] localizedDescription]];
            break;
    }
    return [description copy];
}

#pragma mark - Internal

- (void)callFulfillmentBlock:(FulfillmentBlock)callback promise:(SHXPromise *)promise value:(id)value queue:(dispatch_queue_t)queue {
    dispatch_async(queue, ^{
        id callbackValue = value;
        if (callback != nil) {
            callbackValue = callback(value);
        }
        handlePromiseWithValue(promise, callbackValue);
    });
}

- (void)callRejectionBlock:(RejectionBlock)callback promise:(SHXPromise *)promise reason:(NSError *)reason queue:(dispatch_queue_t)queue {
    dispatch_async(queue, ^{
        id callbackValue = reason;
        if (callback != nil) {
            callbackValue = callback(reason);
        }
        handlePromiseWithValue(promise, callbackValue);
    });
}

@end
