//
// Created by Artyom on 5/14/2023.
//
#include "main.h"
#include <mm_malloc.h>

extern void drawLevel(void* contex, void* game);
extern void loadLevels(void *game);
int main() {

    Level_t* level = aligned_alloc(64, sizeof(Level_t)*3);
    void *context = initContext();


    GameStruct_t gameStruct = {
            {{400.f, 700.f}, {0.4f, -0.4f}, 0x00FF00, 10},
            {{200.f, 600.f}, {100, 10}, 0xff0000, 10.f},
            {50, 20}, level, level, 3, 0};


    loadLevels(&gameStruct);

    openWindow(context);

    drawLevel(context, &gameStruct);
    createCanvas(context);

    drawFB(context);

    mainLoop(context, (void (*)(void *, void *)) eventHandler, &gameStruct);

    return 0;
}