# SHXPromise

SHXPromise provides simple tools for organizing asynchronous code.

Specifically, it is a tiny implementation of [Promises/A+ spec](https://github.com/promises-aplus/promises-spec) in Objective-C.

It works both on iOS (5.0 and later) and OS X(10.7 and later).

It delivers all promises asynchronously, even if the value is already available, to help you write consistent code that doesn't change if the underlying data provider changes from synchronous to asynchronous.

## Install

There are a few different installation options:

* Cocoapods (recommended)
* Drag-n-drop

Regardless of the installation method, you can actually start working with the SHXPromise class by simply importing it wherever you need:

```objc
#import "SHXPromise.h"
```

### Cocoapods

Cocoapods is a nice dependency manager for iOS and OSX apps. Take a look at the [Cocoapods website](https://github.com/CocoaPods/CocoaPods) to get started if you're not familiar.

Once cocoapods is set up, just add:

```ruby
pod 'SHXPromise'
```

### Drag-n-drop

SHXPromise is really just two files: **SHXPromise.h** and **SHXPromise.m**.
You can clone this repo, and simply drag those two files into your Xcode project.
Make sure the "Copy items into destination group's folder (if needed)" checkbox is checked, and your main project target is checked, and that none of the names clash.

## Basic Usage

```objective-c
SHXPromise *promise = [[]SHXPromise alloc] init];

[promise onFulfilled:^id(id value) {
    // success
} rejected:^id(NSError *reason) {
    // failure
}];

// on succeed
[promise resolve:value];

// on reject
[promise reject:reason];
```

Once a promise has been resolved or rejected, it cannot be resolved or rejected again.

Here is an example of a simple AFNetworking wrapper:

```objective-c
- (SHXPromise *)getJSON:(NSString *)urlString {
  SHXPromise *promise = [[SHXPromise alloc] init];
  
  NSURL *url = [NSURL URLWithString:urlString];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
    [promise fulfill:JSON];
  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
    [promise reject:error];
  }];
  
  [operation start];
  return promise;
}
```

## Chaining

One of the really awesome features of Promises/A+ promises are that they can be chained together. In other words, the return value of the first resolve handler will be passed to the second resolve handler.

If you return a regular value, it will be passed, as is, to the next `fulfilled` handler.

```objective-c
[[[self getJSON:@"posts.json"] onFulfilled:^id(id json) {
    return [value objectForKey:@"post"];
}] onFulfilled:^id(id post) {
    // proceed
}];
```

If you return a NSError object, it will be passed to the next `rejected` handler:

```objective-c
[[[self getJSON:@"posts.json"] onFulfilled:^id(id json) {
    return [NSError errorWithDomain:@"SHXTest" code:1 userInfo:@{}];
}] onRejected:^id(NSError *reason) {
    // handle error
}];
```

The really awesome part comes when you return a promise from the first handler:

```objective-c
[[[self getJSON:@"posts/1.json"] onFulfilled:^id(id post) {
    return [self getJSON:[post objectForKey:@"commentURL"]];
}] onFulfilled:^id(id comments) {
    // proceed with access to posts and comments
}];
```

This allows you to flatten out nested callbacks, and is the main feature of promises that prevents "rightward drift" in programs with a lot of asynchronous code.

Errors also propagate. You can use this to emulate `try/catch` logic in synchronous code. Simply chain as many resolve callbacks as a you want, and add a failure handler at the end to catch errors.

```objective-c
[[[[self getJSON:@"posts/1.json"] onFulfilled:^id(id post) {
    return [self getJSON:[post objectForKey:@"commentURL"]];
}] onFulfilled:^id(id comments) {
    // proceed with access to posts and comments
}] onRejected:^id(NSError *reason) {
    // handle errors in either of the two requests
}];
```

## Arrays of promises

Sometimes you might want to work with many promises at once.
If you pass an array of promises to the `all:` method it will return a new promise that will be fulfilled when all of the promises in the array have been fulfilled; or rejected immediately if any promise in the array is rejected.

```objective-c
NSArray *postURLs = @[...];
NSMutableArray *promises = [NSMutableArray array];

for (NSString *url in postURLs) {
    [promises addObject:[self getJSON:url]];
}

[[SHXPromise all:promises] onFulfilled:^id(id posts) {
    // posts contains an array of results for the given promises
}]
```

## Contact

Stefan Huber

- http://github.com/MSNexploder
- http://twitter.com/MSNexploder
- MSNexploder@gmail.com

## License

SHXPromise is available under the MIT license. See the LICENSE file for more info.