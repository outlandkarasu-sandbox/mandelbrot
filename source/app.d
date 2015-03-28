module app;

import std.c.string;
import std.exception;
import std.math;
import std.string;
import std.stdio;

import derelict.sdl2.sdl;

enum {
    WIDTH = 640, /// ウィンドウの幅
    HEIGHT = 640, /// ウィンドウの高さ
}

/// ウィンドウタイトル
enum TITLE = "Mandelblot";

/// 背景色
enum BackColor : Uint8 {
    R = 0,
    G = 0,
    B = 0,
    A = Uint8.max,
}

/// 描画色
enum PlotColor : Uint8 {
    R = Uint8.max,
    G = 0,
    B = 0,
    A = Uint8.max,
}

enum {
    MIN_X = -2.0,
    MAX_X = 2.0,
    MIN_Y = -2.0,
    MAX_Y = 2.0,
    SIZE_X = MAX_X - MIN_X,
    SIZE_Y = MAX_Y - MIN_Y,
    STEP_X = SIZE_X / WIDTH,
    STEP_Y = SIZE_Y / HEIGHT,
}

/// SDLのロード
static this() {
    DerelictSDL2.load();
}


enum {
    DIVERGE_LIMIT = 100.0, /// 発散の閾値
    RECUSIVE_COUNT = 1000,
}

/// マンデルブロ集合の計算
bool mandelbrot(double a, double b, double x = 0.0, double y = 0.0, size_t n = 0) @safe pure nothrow @nogc {
    if(n > RECUSIVE_COUNT) {
        return true;
    }

    immutable x2 = x * x;
    immutable y2 = y * y;
    if(x2 + y2 > DIVERGE_LIMIT) {
        return false;
    }

    return mandelbrot(a, b, x2 - y2 + a, 2.0 * x * y + b, n + 1);
}

/// メイン関数
void main() {
    // SDL初期化
    enforceSdl(SDL_Init(SDL_INIT_EVERYTHING) == 0);
    scope(exit) SDL_Quit();

    // ウィンドウの生成・表示
    auto window = enforceSdl(SDL_CreateWindow(
        toStringz(TITLE),
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        WIDTH,
        HEIGHT,
        SDL_WINDOW_SHOWN));
    scope(exit) SDL_DestroyWindow(window);

    // レンダラーの生成
    auto renderer = enforceSdl(SDL_CreateRenderer(
        window,
        -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC));
    scope(exit) SDL_DestroyRenderer(renderer);

    // 画面クリア
    SDL_SetRenderDrawColor(
        renderer,
        BackColor.R,
        BackColor.G,
        BackColor.B,
        BackColor.A);
    enforceSdl(SDL_RenderClear(renderer) == 0);

    // 点の描画用関数
    void plot(double x, double y) {
        SDL_RenderDrawPoint(renderer, cast(int)((x - MIN_X) * WIDTH / SIZE_X), cast(int)((y - MIN_Y) * HEIGHT / SIZE_Y));
    }

    // 描画実行
    SDL_SetRenderDrawColor(
        renderer,
        PlotColor.R,
        PlotColor.G,
        PlotColor.B,
        PlotColor.A);
    for(double y = MIN_Y; y < MAX_Y; y += STEP_Y) {
        for(double x = MIN_X; x < MAX_X; x += STEP_X) {
            if(mandelbrot(x, y, 0, 0)) {
                plot(x, y);
            }
        }
    }
    SDL_RenderPresent(renderer);

    // イベントループ
    mainLoop: for(SDL_Event event; SDL_WaitEvent(&event);) {
        switch(event.type) {
        // マウスボタンクリックやウィンドウクローズで終了
        case SDL_MOUSEBUTTONDOWN:
        case SDL_QUIT:
            break mainLoop;
        default:
            break;
        }
    }
}

/**
 *  SDLのエラーメッセージの取得
 *
 *  Returns:
 *      SDLのエラーメッセージ。エラーが無ければnull。
 */
@trusted string getSdlMessage() {
    if(auto msg = SDL_GetError()) {
        return msg[0 .. strlen(msg)].idup;
    } else {
        return null;
    }
}

/**
 *  SDL関数のエラーチェック
 *
 *  Params:
 *      value = SDL関数の戻り値か、エラーチェック結果。
 *  Returns:
 *      エラーが発生していなければvalue。
 *  Throws:
 *      Exception エラーが発生していた場合にスローされる。
 */
T enforceSdl(T)(T value, string file = __FILE__, size_t line = __LINE__) {
    return enforce(value, getSdlMessage(), file, line);
}

