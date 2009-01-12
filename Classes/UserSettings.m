#import "UserSettings.h"

@implementation UserSettings

@synthesize version;
@synthesize userName;
@synthesize password;
@synthesize imageSize;
@synthesize useMobileProxy;
@synthesize shouldAutoRotation;

- (id)init {
	if (self = [super init]) {
		version = CURRENT_VERSION;
		userName = [[NSString alloc] init];
		password = [[NSString alloc] init];
		imageSize = UserSettingsImageSizeMedium;
		useMobileProxy = NO;
		shouldAutoRotation = YES;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
	version = [coder decodeIntForKey:@"version"];
	userName = [[coder decodeObjectForKey:@"userName"] retain];
	password = [[coder decodeObjectForKey:@"password"] retain];
	imageSize = [coder decodeIntForKey:@"imageSize"];
	useMobileProxy = [coder decodeBoolForKey:@"useMobileProxy"];
	shouldAutoRotation = [coder decodeBoolForKey:@"shouldAutoRotation"];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeInt:version forKey:@"version"];
	[encoder encodeObject:userName forKey:@"userName"];
	[encoder encodeObject:password forKey:@"password"];
	[encoder encodeInt:imageSize forKey:@"imageSize"];
	[encoder encodeBool:useMobileProxy forKey:@"useMobileProxy"];
	[encoder encodeBool:shouldAutoRotation forKey:@"shouldAutoRotation"];
}

- (void)dealloc {
	[userName release];
	[password release];
	[super dealloc];
}

@end
