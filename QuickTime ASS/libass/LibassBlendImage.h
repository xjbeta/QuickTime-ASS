//
//  LibassBlendImage.h
//  Eriri
//
//  Created by xjbeta on 2020/11/6.
//  Copyright © 2020 xjbeta. All rights reserved.
//

#ifndef LibassBlendImage_h
#define LibassBlendImage_h

#include <stdio.h>
#include <ass.h>

typedef struct image_s {
    int x, y, width, height, stride;
    unsigned char *buffer;      // RGB24
} image_t;

image_t blendBitmapData(ASS_Image *img, int width, int height);

#endif /* LibassBlendImage_h */


