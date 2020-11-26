//
//  XSFunctions.m
//  PDF
//
//  Created by mac on 2020/4/19.
//  Copyright © 2020 mac. All rights reserved.
//

#import "XSFunctions.h"

//_______________________________________________________________________________________________________________
// MARK: - UIFont

__attribute__((overloadable)) UIFont* font(CGFloat size) {
    return [UIFont systemFontOfSize:size weight:UIFontWeightRegular];
}

__attribute__((overloadable)) UIFont* font(CGFloat size, UIFontWeight weight) {
    return [UIFont systemFontOfSize:size weight:weight];
}

//_______________________________________________________________________________________________________________
// MARK: - UIColor

__attribute__((overloadable)) UIColor* rgb(int red, int green, int blue) {
    return [UIColor colorWithRed:red/255.0
                           green:green/255.0
                            blue:blue/255.0
                           alpha:1.0];
}

__attribute__((overloadable)) UIColor* rgb(int red, int green, int blue, CGFloat alpha) {
    return [UIColor colorWithRed:red/255.0
                           green:green/255.0
                            blue:blue/255.0
                           alpha:alpha];
}

__attribute__((overloadable)) UIColor* rgb(int hex) {
    return [UIColor colorWithRed:((hex & 0xFF0000) >> 16)/255.0
                           green:((hex & 0xFF00) >> 8)/255.0
                            blue:((hex & 0xFF))/255.0
                           alpha:1.0];
}

__attribute__((overloadable)) UIColor* rgb(const char *str) {
    return [UIColor colorWithRed:((strtol(str, NULL, 16) & 0xFF0000) >> 16)/255.0
                           green:((strtol(str, NULL, 16) & 0xFF00) >> 8)/255.0
                            blue:((strtol(str, NULL, 16) & 0xFF))/255.0
                           alpha:1.0];
}

//_______________________________________________________________________________________________________________
// MARK: -

void _clean_up_function(void (^*block)(void)) {
    (*block)();
}
