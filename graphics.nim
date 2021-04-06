import sdl2 as sdl, sdl2/image as image
import clocks, events
import sugar, tables, math

discard sdl.setHint(HINT_RENDER_SCALE_QUALITY, "1")

const RendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync

type
    KeybindCallback* = (int) -> void

    Screen* = object
        window: sdl.WindowPtr
        renderer*: sdl.RendererPtr

        clock*: Clock[5]
        event_bus*: ref EventBus
        key_calls: Table[string, seq[KeybindCallback]]

        running: bool
        real_fps*: float

    Image* = ref object
        texture*: sdl.TexturePtr
        w*, h*: int


proc draw*(screen: var Screen, img: Image, x, y: cint) =
    var r: sdl.Rect = (x, y, cint img.w, cint img.h)
    screen.renderer.copy(img.texture, nil, addr r)
proc drawRotated*(screen: var Screen, img: Image, x, y: cint, angle: float) =
    var r: sdl.Rect = (x, y, cint img.w, cint img.h)
    screen.renderer.copyEx(img.texture, nil, addr r, angle, nil)

proc loadImage*(screen: var Screen, fpath: string): Image =
    new result
    result.texture = screen.renderer.loadTexture(fpath)
    discard result.texture.queryTexture(nil, nil,
        cast[ptr cint](addr result.w), cast[ptr cint](addr result.h))
proc freeImage*(img: Image) =
    destroyTexture(img.texture)

proc initScreen*(title: string, width, height: int, event_bus: ref EventBus, bg_color=(0,0,0)): Screen =
    discard image.init(IMG_INIT_PNG or IMG_INIT_JPG or IMG_INIT_TIF)
    discard sdl.init(INIT_EVERYTHING)

    result.window = sdl.createWindow(
        title,
        sdl.SDL_WINDOWPOS_UNDEFINED, sdl.SDL_WINDOWPOS_UNDEFINED,
        cint width,
        cint height,
        0  # window flags
    )
    result.renderer = result.window.createRenderer(-1, RendererFlags);
    discard result.renderer.setDrawColor(uint8 bg_color[0], uint8 bg_color[1], uint8 bg_color[2], 255)

    result.event_bus = event_bus
    event_bus.add_event("draw")
    result.key_calls = initTable[string, seq[KeybindCallback]]()

    result.running = true

proc exit*(screen: var Screen) =
    screen.running = false
    screen.renderer.destroyRenderer()
    screen.window.destroyWindow()
    image.quit()
    echo "Clean shutdown."
    sdl.quit()


proc keybind*(screen: var Screen, key_name: string, cb: KeybindCallback) =
    discard screen.key_calls.hasKeyOrPut(key_name, newSeq[KeybindCallback]())
    screen.key_calls[key_name].add cb

template bind_key*(screen: var Screen, key_name: string, code: untyped): untyped =
    screen.keybind(key_name, proc(n: int) = code)

proc clear*(screen: var Screen) =
    screen.renderer.clear()
proc update*(screen: var Screen) =
    screen.renderer.present()


proc processInputs*(screen: var Screen) =
    var evt = sdl.defaultEvent
    while pollEvent(evt):
        case evt.kind
        of QuitEvent:
            screen.exit()
        else:
            discard

    let inputs = sdl.getKeyboardState(nil)
    var n: uint8
    for key_name, callbacks in screen.key_calls.pairs():
        n = inputs[int getScancodeFromName cstring key_name]
        if n > 0:
            for cb in callbacks:
                cb(int n)


proc mainloop*(screen: var Screen, fps: float) =
    var interval, to_wait: float

    screen.real_fps = fps

    if fps > 0:
        interval = 1/fps

    while screen.running:
        screen.clock.reset(0)

        screen.processInputs()
        screen.clear()
        screen.event_bus.trigger("draw")
        screen.update()

        to_wait = interval - screen.clock.poll(0)
        if to_wait > 0:
            sleep(int floor to_wait*1000)

        screen.real_fps = 1 / screen.clock.poll(0)
        #echo "FPS: ", round(screen.real_fps, 2)
        #echo "Slept: ", int floor to_wait*1000


when isMainModule:
    const
        WINDOW_TITLE = "Game Test"
        WIDTH = 640
        HEIGHT = 480
        FPS = 0

    var
        bus = new EventBus
        screen = initScreen(WINDOW_TITLE, WIDTH, HEIGHT, bus)
        img = screen.loadImage("assets/textures/test.png")

        x, y: float
        speed = 200.0

    img.w = 128
    img.h = 128
    x = (WIDTH - img.w).float * 0.5
    y = (HEIGHT - img.h).float * 0.5

    bus.register("draw", proc() = screen.draw(img, cint x, cint y))

    screen.bind_key "Up": y -= speed/screen.real_fps
    screen.bind_key "Down": y += speed/screen.real_fps
    screen.bind_key "Left": x -= speed/screen.real_fps
    screen.bind_key "Right": x += speed/screen.real_fps

    screen.mainloop(FPS)
