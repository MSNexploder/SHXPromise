//
//  SHXPromise.h
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

#import <Foundation/Foundation.h>

typedef id(^FulfillmentBlock)(id value);
typedef id(^RejectionBlock)(NSError *reason);

@interface SHXPromise : NSObject

/**
 * A container for the future value of the promise.
 *
 * @note Only contains useful information once the promise was fulfilled.
 * @return The fulfillment value.
 */
@property (nonatomic, strong, readonly) id value;

/**
 * A container for the future rejection reason of the promise.
 *
 * @note Only contains useful information once the promise was rejected.
 * @return The rejection reason.
 */
@property (nonatomic, strong, readonly) NSError *reason;

/**
 * Asks the promise if it is pending.
 *
 * @return A flag indicating if the promise is still pending.
 */
@property (nonatomic, readonly) BOOL isPending;

/**
 * Asks the promise if it has been fulfilled.
 *
 * @return A flag indicating if the promise was fulfilled.
 */
@property (nonatomic, readonly) BOOL isFulfilled;

/**
 * Asks the promise if it has been rejected.
 *
 * @return A flag indicating if the promise was rejected.
 */
@property (nonatomic, readonly) BOOL isRejected;

/**
 * Return a new promise that will be fulfilled when all of the promises in the array have been fulfilled;
 * or rejected immediately if any promise in the array is rejected.
 * 
 * @param promises Array of input promises.
 * @return A new promise that will be fulfilled when all of the promises in the array have been fulfilled.
 */
+ (SHXPromise *)all:(NSArray *)promises;

/**
 * Return a new promise that will be fulfilled when all of the promises in the dictionary have been fulfilled;
 * or rejected immediately if any promise in the dictionary is rejected.
 *
 * @param promises Dictionary of input promises.
 * @return A new promise that will be fulfilled when all of the promises in the dictionary have been fulfilled.
 */
+ (SHXPromise *)dictionary:(NSDictionary *)promises;

/**
 * Overwrite on subclasses to automatically copy additional properties to promises created on callback registration.
 * @return Array of property keys which should be automatically copied.
 */
+ (NSArray *)additionalPropertyKeys;

/**
 * Registers both, an fulfillment and rejection block.
 *
 * @note Can be called multiple times. Registered actions will be resolved in order.
 * @note onFulfilled / onRejected will be called on the main queue.
 * @param onFulfilled A block which will be called if the promise was successfully fulfilled.
 * The returned value from the block will be used to resolve returned promise.
 * @param onRejected A block which will be called if the promise was rejected.
 * The returned value from the block will be used to resolve the returned promise.
 * @return A new promise.
 */
- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled rejected:(RejectionBlock)onRejected;

/**
 * Registers an fulfillment block.
 *
 * @note Can be called multiple times. Registered actions will be resolved in order.
 * @note onFulfilled / onRejected will be called on the main queue.
 * @param onFulfilled A block which will be called if the promise was successfully fulfilled.
 * The returned value from the block will be used to resolve returned promise.
 * @return A new promise.
 */
- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled;

/**
 * Registers an rejection block.
 *
 * @note Can be called multiple times. Registered actions will be resolved in order.
 * @note onFulfilled / onRejected will be called on the main queue.
 * @param onRejected A block which will be called if the promise was rejected.
 * The returned value from the block will be used to resolve the returned promise.
 * @return A new promise.
 */
- (instancetype)onRejected:(RejectionBlock)onRejected;

/**
 * Registers both, an fulfillment and rejection block.
 *
 * @note Can be called multiple times. Registered actions will be resolved in order.
 * @param onFulfilled A block which will be called if the promise was successfully fulfilled.
 * The returned value from the block will be used to resolve returned promise.
 * @param onRejected A block which will be called if the promise was rejected.
 * The returned value from the block will be used to resolve the returned promise.
 * @param queue A queue on which the onFulfilled / on Rejected block will be called.
 * @return A new promise.
 */
- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled rejected:(RejectionBlock)onRejected queue:(dispatch_queue_t)queue;

/**
 * Registers an fulfillment block.
 *
 * @note Can be called multiple times. Registered actions will be resolved in order.
 * @param onFulfilled A block which will be called if the promise was successfully fulfilled.
 * The returned value from the block will be used to resolve returned promise.
 * @param queue A queue on which the onFulfilled / on Rejected block will be called.
 * @return A new promise.
 */
- (instancetype)onFulfilled:(FulfillmentBlock)onFulfilled queue:(dispatch_queue_t)queue;

/**
 * Registers an rejection block.
 *
 * @note Can be called multiple times. Registered actions will be resolved in order.
 * @param onRejected A block which will be called if the promise was rejected.
 * The returned value from the block will be used to resolve the returned promise.
 * @param queue A queue on which the onFulfilled / on Rejected block will be called.
 * @return A new promise.
 */
- (instancetype)onRejected:(RejectionBlock)onRejected queue:(dispatch_queue_t)queue;

/**
 * Fulfill the promise with the passed result.
 *
 * In order to successfully keep the promise, the promise must be pending.
 *
 * @param value The successful value that should become the promise's result.
 */
- (void)fulfill:(id)value;
- (void)resolve:(id)value;

/**
 * Rejectes the promise with the passed reason.
 *
 * In order to successfully reject the promise, the promise must be pending.
 *
 * @param reason The NSError that caused the rejection.
 */
- (void)reject:(NSError *)reason;

@end
