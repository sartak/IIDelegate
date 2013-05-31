#import "IIDelegate.h"
#import <objc/runtime.h>

@implementation IIDelegate

static int instanceCount = 0;

+(void) addProtocols:(NSArray *)protocols to:(Class)class {
    for (Protocol *protocol in protocols) {
        BOOL ok = class_addProtocol(class, protocol);
        if (!ok) {
            [NSException raise:NSInternalInconsistencyException format:@"Error adding protocol <%s>", protocol_getName(protocol)];
        }
    }
}

+(NSDictionary *)typeDictionaryFor:(Class) class {
    NSMutableDictionary *typeDictionary = [NSMutableDictionary dictionary];

    unsigned int protocolCount;
    Protocol **protocolList = class_copyProtocolList(class, &protocolCount);

    for (int p = 0; p < protocolCount; ++p) {
        Protocol *protocol = protocolList[p];
        unsigned int methodCount;

        // required methods
        struct objc_method_description *descriptions = protocol_copyMethodDescriptionList(protocol, YES, YES, &methodCount);
        for (int m = 0; m < methodCount; ++m) {
            NSString *types = [NSString stringWithUTF8String:descriptions[m].types];
            NSString *sel = NSStringFromSelector(descriptions[m].name);
            [typeDictionary setObject:types forKey:sel];
        }
        free(descriptions);

        // optional methods
        descriptions = protocol_copyMethodDescriptionList(protocol, NO, YES, &methodCount);
        for (int m = 0; m < methodCount; ++m) {
            NSString *types = [NSString stringWithUTF8String:descriptions[m].types];
            NSString *sel = NSStringFromSelector(descriptions[m].name);
            [typeDictionary setObject:types forKey:sel];
        }
        free(descriptions);
    }

    return [typeDictionary copy];
}

+(void) addMethods:(NSDictionary *)methods to:(Class)class {
    NSDictionary *typeDictionary = [self typeDictionaryFor:class];

    [methods enumerateKeysAndObjectsUsingBlock:^(NSString *methodName, id block, BOOL *stop) {
        SEL selector = NSSelectorFromString(methodName);
        IMP implementation = imp_implementationWithBlock(block);
        NSString *types = [typeDictionary objectForKey:methodName];

        if (!types) {
            [NSException raise:NSInternalInconsistencyException format:@"You may only add methods from the protocols you've declared; method %@ is not included in protocols <%@>", methodName, [[IIDelegate protocolsForClass:class] componentsJoinedByString:@", "]];
        }

        BOOL ok = class_addMethod(class, selector, implementation, [types UTF8String]);
        if (!ok) {
            [NSException raise:NSInternalInconsistencyException format:@"Error adding method %@", methodName];
        }
    }];
}

+(id) delegateForProtocols:(NSArray *)protocols withMethods:(NSDictionary *)methods {
    if (![protocols count]) {
        [NSException raise:NSInternalInconsistencyException format:@"You must declare at least one protocol for IIDelegate"];
    }

    NSString *className = [NSString stringWithFormat:@"IIDelegate_Anon_%d", ++instanceCount];
    Class class = objc_allocateClassPair([IIDelegate class], [className cStringUsingEncoding:NSUTF8StringEncoding], 0);

    [self addProtocols:protocols to:class];
    [self addMethods:methods to:class];

    objc_registerClassPair(class);

    id instance = [[class alloc] init];
    return instance;
}

+(id) delegateForProtocol:(Protocol *)protocol withMethods:(NSDictionary *)methods {
    return [self delegateForProtocols:@[protocol] withMethods:methods];
}

+(NSArray *) protocolsForClass:(Class)class {
    unsigned int protocolCount;
    Protocol **protocolList = class_copyProtocolList(class, &protocolCount);

    NSMutableArray *protocolsDescription = [NSMutableArray arrayWithCapacity:protocolCount];

    for (int p = 0; p < protocolCount; ++p) {
        const char *name = protocol_getName(protocolList[p]);
        [protocolsDescription addObject:[NSString stringWithUTF8String:name]];
    }

    free(protocolList);

    return [protocolsDescription copy];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ <%@>", [super description], [IIDelegate protocolsForClass:[self class]]];
}

@end
