#import "ISIconSupport.h"

#include <substrate.h>

NSDictionary * repairIconState(NSDictionary *iconState);

static ISIconSupport *sharedSupport = nil;

@implementation ISIconSupport

+ (id)sharedInstance {
    return sharedSupport;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        extensions = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
    [extensions release];
    [super dealloc];
}

- (NSString *)extensionString {
    if ([extensions count] == 0) {
        return @"";
    }

    // Every combination of extensions must produce a unique extension string
    int result = 0;
    for (NSString *extension in extensions) {
        result |= [extension hash];
    }

    return [@"-" stringByAppendingFormat:@"%x", result];
}

- (BOOL)addExtension:(NSString *)extension {
    if (extension == nil || [extensions containsObject:extension]) {
        return NO;
    }

    [extensions addObject:extension];
    return YES;
}

- (BOOL)isBeingUsedByExtensions {
    return ![[self extensionString] isEqualToString:@""];
}

- (void)repairAndReloadIconState {
    SBIconModel *iconModel = [objc_getClass("SBIconModel") sharedInstance];
    id iconState = [iconModel iconState];
    id newIconState = repairIconState(iconState);
    if (![newIconState isEqual:iconState]) {
        [newIconState writeToFile:[iconModel iconStatePath] atomically:YES];
        [iconModel noteIconStateChangedExternally];
    }
}

@end

__attribute__((constructor)) static void initISIconSupport() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // NOTE: This library should only be loaded for SpringBoard
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleId isEqualToString:@"com.apple.springboard"]) {
        sharedSupport = [[ISIconSupport alloc] init];
    }

    [pool release];
}

/* vim: set filetype=objcpp sw=4 ts=4 expandtab tw=80 ff=unix: */
