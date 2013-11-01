#import "IIDelegate.h"
#import <objc/runtime.h>

#if __has_feature(objc_arc)
#error IIDelegate does not support ARC. You must add -fno-obc-arc to the build rules for IIDelegate.m.
#endif

@implementation IIDelegate

static int instanceCount = 0;

+(Class) delegateClassForProtocols:(NSArray *)protocols {
    if (![protocols count]) {
        [NSException raise:NSInternalInconsistencyException format:@"You must declare at least one protocol for IIDelegate"];
    }

    NSString *className = [NSString stringWithFormat:@"IIDelegate_Anon_%d", ++instanceCount];
    Class class = objc_allocateClassPair([IIDelegate class], [className cStringUsingEncoding:NSUTF8StringEncoding], 0);

    [class addProtocols:protocols];

    return class;
}


+(void) addProtocols:(NSArray *)protocols {
    if ([self class] == [IIDelegate class]) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot addProtocols directly to IIDelegate"];
    }

    for (Protocol *protocol in protocols) {
        BOOL ok = class_addProtocol(self, protocol);
        if (!ok) {
            [NSException raise:NSInternalInconsistencyException format:@"Error adding protocol <%s>", protocol_getName(protocol)];
        }
    }

    unsigned int protocolCount;
    Protocol **protocolList = class_copyProtocolList(self, &protocolCount);

    free(protocolList);
}

+(NSString *)typesForSelector:(SEL)selector {
    unsigned int protocolCount;
    Protocol **protocolList = class_copyProtocolList(self, &protocolCount);
    NSString *types = nil;

    for (int p = 0; p < protocolCount; ++p) {
        Protocol *protocol = protocolList[p];
        struct objc_method_description description;

        description = protocol_getMethodDescription(protocol, selector, YES, YES);
        if (description.name) {
            types = [NSString stringWithUTF8String:description.types];
            break;
        }

        description = protocol_getMethodDescription(protocol, selector, NO, YES);
        if (description.name) {
            types = [NSString stringWithUTF8String:description.types];
            break;
        }
    }

    free(protocolList);
    return types;
}


+(void) addSelector:(SEL)selector withImplementation:(id)block {
    if ([self class] == [IIDelegate class]) {
        if ([self class] == [IIDelegate class]) {
            [NSException raise:NSInvalidArgumentException format:@"Cannot addSelector directly to IIDelegate"];
        }
    }

    IMP implementation = imp_implementationWithBlock(block);

    NSString *types = [self typesForSelector:selector];
    if (!types) {
        [NSException raise:NSInternalInconsistencyException format:@"You may only add methods from the protocols you've declared; method %@ is not included in protocols <%@>", NSStringFromSelector(selector), [[self protocols] componentsJoinedByString:@", "]];
    }

    BOOL ok = class_addMethod(self, selector, implementation, [types UTF8String]);
    if (!ok) {
        [NSException raise:NSInternalInconsistencyException format:@"Error adding method %@", NSStringFromSelector(selector)];
    }
}

+(void) addMethods:(NSDictionary *)methods {
    if ([self class] == [IIDelegate class]) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot addMethods directly to IIDelegate"];
    }

    [methods enumerateKeysAndObjectsUsingBlock:^(NSString *methodName, id block, BOOL *stop) {
        SEL selector = NSSelectorFromString(methodName);
        [self addSelector:selector withImplementation:block];
    }];
}

+(Class) delegateClassForProtocol:(Protocol *)protocol {
    return [self delegateClassForProtocols:@[protocol]];
}

+(id) finalizeDelegate {
    if ([self class] == [IIDelegate class]) {
        [NSException raise:NSInvalidArgumentException format:@"Cannot finalizeDelegate IIDelegate directly"];
    }

    objc_registerClassPair(self);

    id instance = [[self alloc] init];
    return [instance autorelease];
}

+(id) delegateForProtocols:(NSArray *)protocols withMethods:(NSDictionary *)methods {
    Class class = [self delegateClassForProtocols:protocols];
    [class addMethods:methods];

    return [class finalizeDelegate];
}

+(id) delegateForProtocol:(Protocol *)protocol withMethods:(NSDictionary *)methods {
    return [self delegateForProtocols:@[protocol] withMethods:methods];
}

+(NSArray *) protocols {
    unsigned int protocolCount;
    Protocol **protocolList = class_copyProtocolList(self, &protocolCount);

    NSMutableArray *protocolsDescription = [NSMutableArray arrayWithCapacity:protocolCount];

    for (int p = 0; p < protocolCount; ++p) {
        const char *name = protocol_getName(protocolList[p]);
        [protocolsDescription addObject:[NSString stringWithUTF8String:name]];
    }

    free(protocolList);

    return [protocolsDescription copy];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ <%@>", [super description], [[self class] protocols]];
}

-(void) dealloc {
    Class class = [self class];
    [super dealloc];
    objc_disposeClassPair(class);
}

@end
