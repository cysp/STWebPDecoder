//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Scott Talbot.

#import "STWebPURLProtocol.h"

#import "STWebPDecoder.h"


NSString * const STWebPURLProtocolSchemePrefix = @"stwebp-";
static NSUInteger const STWebPURLProtocolSchemePrefixLength = 7;


@interface STWebPURLProtocol () <NSURLConnectionDataDelegate>
@end

@implementation STWebPURLProtocol {
@private
	NSURLConnection *_connection;
	NSMutableData *_responseData;
}

+ (void)register {
	[NSURLProtocol registerClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	if (![request.URL.scheme hasPrefix:STWebPURLProtocolSchemePrefix]) {
		return NO;
	}
	request = [self st_canonicalRequestForRequest:request];
	return [NSURLConnection canHandleRequest:request];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return [self st_canonicalRequestForRequest:request];
}

+ (NSURLRequest *)st_canonicalRequestForRequest:(NSURLRequest *)request {
	NSURL * const url = request.URL;
	NSString * const urlScheme = url.scheme;
	if (![urlScheme hasPrefix:STWebPURLProtocolSchemePrefix]) {
		return request;
	}
	NSURL * const modifiedURL = [[NSURL alloc] initWithScheme:[urlScheme substringFromIndex:STWebPURLProtocolSchemePrefixLength] host:url.host path:url.path];
	NSURLRequest * const modifiedRequest = [[NSURLRequest alloc] initWithURL:modifiedURL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
	return modifiedRequest;
}


- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
	if ((self = [super initWithRequest:request cachedResponse:cachedResponse client:client])) {
		request = [self.class canonicalRequestForRequest:request];
		_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
		[_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

		_responseData = [[NSMutableData alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_connection cancel];
}


- (void)startLoading {
	[_connection start];
}

- (void)stopLoading {
	[_connection cancel];
}


#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self.client URLProtocol:self didFailWithError:error];
}


#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
//	[self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSDictionary * const responseHeaderFields = @{
		@"Content-Type": @"image/png",
	};

	NSURLRequest * const request = self.request;
	NSHTTPURLResponse * const modifiedResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.0" headerFields:responseHeaderFields];

	[self.client URLProtocol:self didReceiveResponse:modifiedResponse cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
	[_responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	UIImage *image = [STWebPDecoder imageWithData:_responseData error:NULL];
	NSData *imagePNGData = UIImagePNGRepresentation(image);
	[self.client URLProtocol:self didLoadData:imagePNGData];
	[self.client URLProtocolDidFinishLoading:self];
}

@end
