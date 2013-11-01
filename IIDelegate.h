#import <Foundation/Foundation.h>

@interface IIDelegate : NSObject

+(id) delegateForProtocols:(NSArray *)protocols withMethods:(NSDictionary *)methods;
+(id) delegateForProtocol:(Protocol *)protocol withMethods:(NSDictionary *)methods;


+(Class) delegateClassForProtocols:(NSArray *)protocols;
+(Class) delegateClassForProtocol:(Protocol *)protocol;

+(void) addSelector:(SEL)selector withImplementation:(id)block;

+(id) finalizeDelegate;

@end
