//
//  JSTUtil.m
//  jstalk
//
//  Created by August Mueller on 9/24/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTUtils.h"


void JSTAssignException(JSTBridge *bridge, JSValueRef *exception, NSString *reason) {
    
    JSContextRef ctx              = [bridge jsContext];
    /*
    // Gather call stack
    JSValueRef callStackException = nil;
    JSStringRef scriptJS          = JSStringCreateWithUTF8CString("return dumpCallStack()");
    JSObjectRef fn                = JSObjectMakeFunction(ctx, nil, 0, nil, scriptJS, nil, 0, nil);
    JSValueRef result             = JSObjectCallAsFunction(ctx, fn, nil, 0, nil, &callStackException);
    JSStringRelease(scriptJS);
    
    if (!callStackException) {
        
        // Convert call stack to string
        JSStringRef resultStringJS = JSValueToStringCopy(ctx, result, nil);
        NSString* callStack        = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, resultStringJS);
        JSStringRelease(resultStringJS);
        [NSMakeCollectable(callStack) autorelease];
        
        // Append call stack to exception
        if ([callStack length]) {
            reason = [NSString stringWithFormat:@"%@\n%@", reason, callStack];
        }
    }
    */
    
    // Convert exception to string
    JSStringRef jsName  = JSStringCreateWithUTF8CString([reason UTF8String]);
    JSValueRef jsString = JSValueMakeString(ctx, jsName);
    JSStringRelease(jsName);
    
    // Convert to object to allow JavascriptCore to add line and sourceURL
    *exception = JSValueToObject(ctx, jsString, nil);
}


id JSTNSObjectFromValue(JSTBridge *bridge, JSValueRef value) {
    
    JSContextRef ctx = [bridge jsContext];
    JSType type = JSValueGetType(ctx, value);
    
    if (type == kJSTypeBoolean) {
        return [NSNumber numberWithBool:JSValueToBoolean(ctx, value)];
    }
    else if (type == kJSTypeNumber) {
        return [NSNumber numberWithDouble:JSValueToNumber(ctx, value, nil)];
    }
    else if (type == kJSTypeString) {
        JSStringRef s = JSValueToStringCopy(ctx, value, nil);
        NSString *ret = [(NSString*)JSStringCopyCFString(kCFAllocatorDefault, s) autorelease];
        JSStringRelease(s);
        return ret;
    }
    else if (type == kJSTypeObject) {
        id o = [bridge NSObjectForJSObject:(JSObjectRef)value];
        JSTAssert(o);
        return o;
    }
    else {
        debug(@"not sure what to do with this object!");
    }
    
    return nil;
}

SEL JSTSelectorFromValue(JSTBridge *bridge, JSValueRef value) {
    JSContextRef ctx = [bridge jsContext];
    JSType type = JSValueGetType(ctx, value);
    
    if (type == kJSTypeString || type == kJSTypeObject) {
        NSString *s = JSTNSObjectFromValue(bridge, value);
        
        if (![s isKindOfClass:[NSString class]]) {
            NSLog(@"%s:%d", __FUNCTION__, __LINE__);
            NSLog(@"Can't make a selector out of %@", s);
            return nil;
        }
        
        return NSSelectorFromString(s);
    }
    
    if (type == kJSTypeObject) {
        JSTAssert(false); // we need to handle selectors here.
    }
    
    return nil;
}

long JSTLongFromValue(JSTBridge *bridge, JSValueRef value) {
    return (long)JSTDoubleFromValue(bridge, value);
}

double JSTDoubleFromValue(JSTBridge *bridge, JSValueRef value) {
    return JSValueToNumber([bridge jsContext], value, nil);
}

ffi_type* JSTFFITypeForBridgeDeclaredType(NSString *type) {
    
    if (![type length]) {
        return &ffi_type_void;
    }
    
    if ([type isEqualToString:@"BOOL"]) {
        return &ffi_type_sint8;
    }
    
    
    /*
    char c = [encoding characterAtIndex:0];
    
    switch (c) {
        case _C_ID:
        case _C_CLASS:
        case _C_SEL:
        case _C_PTR:
        case _C_UNDEF:
        case _C_CHARPTR:     return    &ffi_type_pointer;
            
        case _C_CHR:         return    &ffi_type_sint8;
        case _C_UCHR:        return    &ffi_type_uint8;
        case _C_SHT:         return    &ffi_type_sint16;
        case _C_USHT:        return    &ffi_type_uint16;
        case _C_INT:
        case _C_LNG:         return    &ffi_type_sint32;
        case _C_UINT:
        case _C_ULNG:        return    &ffi_type_uint32;
        case _C_LNG_LNG:     return    &ffi_type_sint64;
        case _C_ULNG_LNG:    return    &ffi_type_uint64;
        case _C_FLT:         return    &ffi_type_float;
        case _C_DBL:         return    &ffi_type_double;
        case _C_BOOL:        return    &ffi_type_sint8;
        case _C_VOID:        return    &ffi_type_void;
    }
    */
    
    debug(@"Unknown ffi encoding for '%@'", type);
    
    JSTAssert(false);
    
    return &ffi_type_void;
}


ffi_type* JSTFFITypeForTypeEncoding(NSString *encoding) {
    
    if (![encoding length]) {
        JSTAssert(false);
        return &ffi_type_void;
    }
    
    char c = [encoding characterAtIndex:0];
    
    switch (c) {
        case _C_ID:
        case _C_CLASS:
        case _C_SEL:
        case _C_PTR:
        case _C_UNDEF:
        case _C_CHARPTR:     return    &ffi_type_pointer;
            
        case _C_CHR:         return    &ffi_type_sint8;
        case _C_UCHR:        return    &ffi_type_uint8;
        case _C_SHT:         return    &ffi_type_sint16;
        case _C_USHT:        return    &ffi_type_uint16;
        case _C_INT:
        case _C_LNG:         return    &ffi_type_sint32;
        case _C_UINT:
        case _C_ULNG:        return    &ffi_type_uint32;
        case _C_LNG_LNG:     return    &ffi_type_sint64;
        case _C_ULNG_LNG:    return    &ffi_type_uint64;
        case _C_FLT:         return    &ffi_type_float;
        case _C_DBL:         return    &ffi_type_double;
        case _C_BOOL:        return    &ffi_type_sint8;
        case _C_VOID:        return    &ffi_type_void;
    }
    
    debug(@"Unknown ffi encoding for '%@'", encoding);
    
    JSTAssert(false);
    
    return &ffi_type_void;
}


int JSTSizeOfTypeEncoding(NSString *encoding) {
    if (![encoding length]) {
        return 0x00;
    }
    
    char c = [encoding characterAtIndex:0];
    
    switch (c) {
        case    _C_ID:      return    sizeof(id);
        case    _C_CLASS:   return    sizeof(Class);
        case    _C_UNDEF:   return    sizeof(id);
        case    _C_SEL:     return    sizeof(SEL);
        case    _C_CHR:     return    sizeof(char);
        case    _C_UCHR:    return    sizeof(unsigned char);
        case    _C_SHT:     return    sizeof(short);
        case    _C_USHT:    return    sizeof(unsigned short);
        case    _C_INT:     return    sizeof(int);
        case    _C_UINT:    return    sizeof(unsigned int);
        case    _C_LNG:     return    sizeof(long);
        case    _C_ULNG:    return    sizeof(unsigned long);
        case    _C_LNG_LNG: return    sizeof(long long);
        case    _C_ULNG_LNG:return    sizeof(unsigned long long);
        case    _C_FLT:     return    sizeof(float);
        case    _C_DBL:     return    sizeof(double);
        case    _C_BOOL:    return    sizeof(BOOL);
        case    _C_VOID:    return    sizeof(void);
        case    _C_PTR:     return    sizeof(void*);
        case    _C_CHARPTR: return    sizeof(char*);
    }
    
    return    -1;
}

NSString *JSTStringForFFIType(ffi_type* type) {
    
    if (type == &ffi_type_void) {
        return @"ffi_type_void";
    }
    else if (type == &ffi_type_uint8) {
        return @"ffi_type_uint8";
    }
    else if (type == &ffi_type_sint8) {
        return @"ffi_type_sint8";
    }
    else if (type == &ffi_type_uint16) {
        return @"ffi_type_uint16";
    }
    else if (type == &ffi_type_sint16) {
        return @"ffi_type_sint16";
    }
    else if (type == &ffi_type_uint32) {
        return @"ffi_type_uint32";
    }
    else if (type == &ffi_type_sint32) {
        return @"ffi_type_sint32";
    }
    else if (type == &ffi_type_uint64) {
        return @"ffi_type_uint64";
    }
    else if (type == &ffi_type_sint64) {
        return @"ffi_type_sint64";
    }
    else if (type == &ffi_type_float) {
        return @"ffi_type_float";
    }
    else if (type == &ffi_type_double) {
        return @"ffi_type_double";
    }
    else if (type == &ffi_type_longdouble) {
        return @"ffi_type_longdouble";
    }
    else if (type == &ffi_type_pointer) {
        return @"ffi_type_pointer";
    }
    
    return @"unknown ffi type";
}



JSValueRef JSTMakeJSValueWithFFITypeAndValue(ffi_type *type, ffi_arg value, JSTBridge *bridge) {
    
    if (type == &ffi_type_void) {
        return JSValueMakeNull([bridge jsContext]);
    }
    else if (type == &ffi_type_pointer) {
        return [bridge makeJSObjectWithNSObject:(id)value runtimeInfo:nil];
    }
    else if (type == &ffi_type_float) {
        return JSValueMakeNumber([bridge jsContext], (float)value);
    }
    else if (type == &ffi_type_double) {
        return JSValueMakeNumber([bridge jsContext], (double)value);
    }
    else if (type == &ffi_type_longdouble) {
        return JSValueMakeNumber([bridge jsContext], (long double)value);
    }
    else if (type == &ffi_type_uint8) {
        return JSValueMakeNumber([bridge jsContext], (uint8_t)value);
    }
    else if (type == &ffi_type_sint8) {
        // well, it's a bool or a char or a ... hrm.  Let's just say it's a bool.
        return JSValueMakeBoolean([bridge jsContext], (bool)value);
    }
    else if (type == &ffi_type_sint32) {
        return JSValueMakeNumber([bridge jsContext], (int32_t)value);
    }
    else if (type == &ffi_type_uint32) {
        return JSValueMakeNumber([bridge jsContext], (uint32_t)value);
    }
    else if (type == &ffi_type_sint16) {
        return JSValueMakeNumber([bridge jsContext], (int16_t)value);
    }
    else if (type == &ffi_type_uint16) {
        return JSValueMakeNumber([bridge jsContext], (uint16_t)value);
    }
    else if (type == &ffi_type_sint64) {
        return JSValueMakeNumber([bridge jsContext], (int64_t)value);
    }
    else if (type == &ffi_type_uint64) {
        return JSValueMakeNumber([bridge jsContext], (uint64_t)value);
    }
    
    return 0x00;
}







