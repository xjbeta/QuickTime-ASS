#include "LibassBlendImage.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ass.h>

static image_t *gen_image(int width, int height)
{
    image_t *img = malloc(sizeof(image_t));
    img->width = width;
    img->height = height;
    img->stride = width * 4;
    img->buffer = (unsigned char *) calloc(1, height * width * 4);
    memset(img->buffer, 0, img->stride * img->height);
    //for (int i = 0; i < height * width * 3; ++i)
    // img->buffer[i] = (i/3/50) % 100;
    return img;
}

#define _r(c)  ((c)>>24)
#define _g(c)  (((c)>>16)&0xFF)
#define _b(c)  (((c)>>8)&0xFF)
#define _a(c)  ((c)&0xFF)


static void blend_single(image_t * frame, ASS_Image *img)
{
    int x, y;
    unsigned char opacity = 255 - _a(img->color);
    unsigned char r = _r(img->color);
    unsigned char g = _g(img->color);
    unsigned char b = _b(img->color);

    unsigned char *src;
    unsigned char *dst;

    src = img->bitmap;
    dst = frame->buffer;
    for (y = 0; y < img->h; ++y) {
        for (x = 0; x < img->w; ++x) {
            unsigned k = ((unsigned) src[x]) * opacity / 255;
            // possible endianness problems
            int s = x * 4;
            
            if (dst[s] == 0) {
                dst[s] = k;
            }
            dst[s + 1] = (k * b + (255 - k) * dst[s + 1]) / 255;
            dst[s + 2] = (k * g + (255 - k) * dst[s + 2]) / 255;
            dst[s + 3] = (k * r + (255 - k) * dst[s + 3]) / 255;
        }
        src += img->stride;
        dst += frame->stride;
    }
}

image_t blendBitmapData(ASS_Image *img)
{
    image_t *frame = gen_image(img->w, img->h);
    frame->x = img->dst_x;
    frame->y = img->dst_y;
    blend_single(frame, img);
    return *frame;
}
