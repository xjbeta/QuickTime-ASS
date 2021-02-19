#include "LibassBlendImage.h"
#include <stdlib.h>
#include <string.h>

static image_t *gen_image(int width, int height)
{
    image_t *img = malloc(sizeof(image_t));
    img->width = width;
    img->height = height;
    img->stride = width * 4;
    int length = height * width * 4;
    img->buffer = (unsigned char *) calloc(1, length);
    memset(img->buffer, 0, length);
    return img;
}

#define _r(c)  ((c)>>24)
#define _g(c)  (((c)>>16)&0xFF)
#define _b(c)  (((c)>>8)&0xFF)
#define _a(c)  ((c)&0xFF)

#define FFMAX(a,b) ((a) > (b) ? (a) : (b))
#define FFMIN(a,b) ((a) > (b) ? (b) : (a))


static void blend_single(image_t * frame, ASS_Image *img)
{
    int x, y;
    unsigned char opacity = ~_a(img->color);
    unsigned char r = _r(img->color);
    unsigned char g = _g(img->color);
    unsigned char b = _b(img->color);

    unsigned char *src;
    unsigned char *dst;

    src = img->bitmap;
    
    int h = FFMIN(img->h, frame->height - img->dst_y);
//    int w = FFMIN(img->w, (frame->width / 4) - img->dst_x);
    int w = img->w;
    
    dst = frame->buffer + img->dst_x * 4 + img->dst_y * frame->stride;
    
    for (y = 0; y < h; ++y) {
        for (x = 0; x < w; ++x) {
            int s = x * 4;
            unsigned k = ((unsigned) src[x]) * opacity >> 8;
            
            // BGRA
            
            if (k == 0) {
                continue;
            } else if (k == 255) {
                dst[s] = b;
                dst[s + 1] = g;
                dst[s + 2] = r;
                dst[s + 3] = k;
                continue;
            } else {
                int kk = 255 - k;
                
                dst[s] = (k * b + kk * dst[s]) >> 8;
                dst[s + 1] = (k * g + kk * dst[s + 1]) >> 8;
                dst[s + 2] = (k * r + kk * dst[s + 2]) >> 8;
                dst[s + 3] = (255 * 255 - kk * (255 - dst[s + 3])) >> 8;
            }
            
        }
        src += img->stride;
        dst += frame->stride;
    }
}

static void blend(image_t * frame, ASS_Image *img)
{
    int cnt = 0;
    while (img) {
        blend_single(frame, img);
        ++cnt;
        img = img->next;
    }
    printf("%d images blended\n", cnt);
}

image_t blendBitmapData(ASS_Image *img, int width, int height)
{
    image_t *frame = gen_image(width, height);
    blend(frame, img);
    return *frame;
}
