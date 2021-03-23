import sdl2 as sdl, sdl2/image as image, sdl2/gfx
import clocks

const
    WINDOW_TITLE = "Game Test"
    WIDTH = 640
    HEIGHT = 480
    RendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync

type
    Game = ref object
        window: sdl.WindowPtr
        renderer: sdl.RendererPtr

    Image = ref object of RootObj
        texture: sdl.TexturePtr
        w, h: int


proc draw(game: Game, img: Image, x, y: int) =
    var r: sdl.Rect = (x: cint x, y: cint y, w: cint img.w, h: cint img.h)
    game.renderer.copy(img.texture, nil, addr r)

proc loadImage(game: Game, fpath: string): Image =
    new result
    result.texture = game.renderer.loadTexture(fpath)
    result.texture.queryTexture(nil, nil, cast[ptr cint](addr result.w), cast[ptr cint](addr result.h))
    return result

proc initGame(): Game =
    discard image.init(IMG_INIT_PNG or IMG_INIT_JPG or IMG_INIT_TIF)
    discard sdl.init(INIT_EVERYTHING)

    new result
    result.window = sdl.createWindow(
        WINDOW_TITLE,
        sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED,
        WIDTH,
        HEIGHT,
        0  # window flags
    )
    result.renderer = result.window.createRenderer(-1, RendererFlags);
    discard result.renderer.setDrawColor(0, 0, 0, 255)

proc exit(game: Game) =
    game.renderer.destroyRenderer()
    game.window.destroyWindow()
    image.quit()
    echo "Clean shutdown."
    sdl.quit()


proc clear(game: Game) =
    game.renderer.clear()

proc update(game: Game) =
    game.renderer.present()

when isMainModule:
    var
        game = initGame()
        img = game.loadImage("assets/textures/test.png")


    game.clear()
    game.update()
    sleep(300)
    game.draw(img, 50, 50)
    game.update()
    sleep(1000)

    game.exit()