//
// Created by Artyom on 5/30/2023.
//

#ifndef NASM_PROJECT_MAIN_H
#define NASM_PROJECT_MAIN_H

#include <X11/Xlib.h>


typedef struct RenderContext_def {
    Display *display_ptr;
    Window window;
    GC gc;
    char *front;
    XImage* img;
    int screen_num;
    unsigned int width;
    unsigned int height;
} RenderContext;

typedef struct Point{
    float x, y;
}Point_t;
typedef struct Ball{
    Point_t pos;
    Point_t d;
    u_int32_t color;
    u_int32_t size;
}Ball_t;
typedef struct Platform{
    Point_t pos;
    Point_t size;
    u_int32_t color;
    float v;
}Platform_t;
typedef struct Block{
    u_int32_t width;
    u_int32_t height;
}Block_t;
typedef struct Level{
    u_int64_t mask[8];//16*4*4 => 16bit * 16 layers
    u_int32_t colors[16*16];
}Level_t;

typedef struct GameStruct{
    Ball_t ball;
    Platform_t platform;
    Block_t blockProps;
    Level_t* currentLevel;
    Level_t* levels;
    u_int32_t levelCount;
    u_int32_t currentLevelIdx;

} GameStruct_t;


extern void openWindow(void* );
extern void createCanvas(void* );
extern void drawFB(void*);
extern void mainLoop(void *, void(*)(void*, void*), void *);

extern void *initContext();

extern void drawLine(void*, int, int, int, int, u_int32_t);
extern void drawCircle(void*, int, int, int, u_int32_t);
extern void drawRectangle(void*, int, int, int, int, u_int32_t);

extern int checkSquareCircleCollision(int circleX, int circleY, int radius, int squareX, int squareY, int squareWidth, int squareHeight);

extern void keyboardHandler(void* game, u_int32_t keyCode);
extern void update(void*, void*);
extern void draw(void*, void*);
extern void eventHandler(void*, void* );

#endif//NASM_PROJECT_MAIN_H
