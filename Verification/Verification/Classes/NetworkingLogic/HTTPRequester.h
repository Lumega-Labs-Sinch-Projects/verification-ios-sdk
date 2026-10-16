//
//  HTTPRequester.h
//
//  Created by BENJAMIN BRYANT BUDIMAN on 05/09/18.
//  Copyright © 2021 Boku, Inc. All rights reserved.
//

#ifndef HTTPRequester_h
#define HTTPRequester_h

#import <Foundation/Foundation.h>

@interface HTTPRequester : NSObject
+ (NSString *)performGetRequest:(NSURL *)url;
+ (NSString *)performGetRequest:(NSURL *)url headers:(NSDictionary<NSString *, NSString *> *)headers;

/// Returns YES when the cellular data interface (`pdp_ip0`) is up and has an IPv4/IPv6 address.
/// Used for Android-parity early fail before seamless initiation (mobile data must be available
/// for the later cellular-bound targetUri GET).
+ (BOOL)isCellularInterfaceAvailable;

/// Decodes bytes actually received from a cellular HTTP(S) response.
///
/// - Important: `length` must be the number of valid response bytes, not the capacity of the
///   backing buffer. Passing the full buffer size (e.g. `sizeof(buffer)`) can include
///   uninitialized memory and make `NSASCIIStringEncoding` return `nil` in Release builds
///   (observed as seamless `Error when executing HTTP requests` on iOS 27).
+ (nullable NSString *)stringFromResponseBuffer:(const void *)buffer length:(NSUInteger)length;

/// ASCII-only decode (no Latin-1 fallback). Used by unit tests to reproduce the pre-fix
/// Release failure when `length` includes non-ASCII unread buffer bytes.
+ (nullable NSString *)asciiStringFromResponseBuffer:(const void *)buffer length:(NSUInteger)length;
@end

#endif /* HTTPRequester_h */
