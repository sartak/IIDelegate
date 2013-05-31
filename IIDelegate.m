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

+(NSDictionary *)typeDictionaryFor:(Class)class requiredMethods:(BOOL)requiredMethods {
    NSMutableDictionary *typeDictionary = [NSMutableDictionary dictionary];

    unsigned int protocolCount;
    Protocol **protocolList = class_copyProtocolList(class, &protocolCount);

    for (int p = 0; p < protocolCount; ++p) {
        Protocol *protocol = protocolList[p];
        unsigned int methodCount;
        struct objc_method_description *descriptions = protocol_copyMethodDescriptionList(protocol, requiredMethods, YES, &methodCount);
        for (int m = 0; m < methodCount; ++m) {
            NSString *types = [NSString stringWithUTF8String:descriptions[m].types];
            NSString *sel = NSStringFromSelector(descriptions[m].name);
            [typeDictionary setObject:types forKey:sel];
        }
        free(descriptions);
    }

    free(protocolList);

    return [typeDictionary copy];
}

+(void) addMethods:(NSDictionary *)methods to:(Class)class {
    NSDictionary *requiredTypes = [self typeDictionaryFor:class requiredMethods:YES];
    NSDictionary *optionalTypes = [self typeDictionaryFor:class requiredMethods:NO];
    NSMutableDictionary *requiredMethods = [requiredTypes mutableCopy];

    [methods enumerateKeysAndObjectsUsingBlock:^(NSString *methodName, id block, BOOL *stop) {
        SEL selector = NSSelectorFromString(methodName);
        IMP implementation = imp_implementationWithBlock(block);
        NSString *types;

        if ((types = [requiredTypes objectForKey:methodName])) {
            [requiredMethods removeObjectForKey:methodName];
        }
        else if ((types = [optionalTypes objectForKey:methodName])) {
            // no action needed
        }
        else {
            [NSException raise:NSInternalInconsistencyException format:@"You may only add methods from the protocols you've declared; method %@ is not included in protocols <%@>", methodName, [[IIDelegate protocolsForClass:class] componentsJoinedByString:@", "]];
        }

        BOOL ok = class_addMethod(class, selector, implementation, [types UTF8String]);
        if (!ok) {
            [NSException raise:NSInternalInconsistencyException format:@"Error adding method %@", methodName];
        }
    }];

    // did they forget some required methods?
    if ([requiredMethods count]) {
        NSArray *methods = [requiredMethods keysSortedByValueUsingSelector:@selector(compare:)];
        [NSException raise:NSInternalInconsistencyException format:@"Required protocol methods (%@) are missing", [methods componentsJoinedByString:@", "]];
    }

    [requiredTypes release];
    [optionalTypes release];
    [requiredMethods release];
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
    return [instance autorelease];
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

-(void) dealloc {
    [super dealloc];
    objc_disposeClassPair([self class]);
}

@end
