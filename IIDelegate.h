#import <Foundation/Foundation.h>

@interface IIDelegate : NSObject

+(id) delegateForProtocols:(NSArray *)protocols withMethods:(NSDictionary *)methods;
+(id) delegateForProtocol:(Protocol *)protocol withMethods:(NSDictionary *)methods;

@end
