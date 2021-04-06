import graphics, events, containers
import sugar
import random, math
import sdl2

randomize()

const
    WIDTH = 2560
    HEIGHT = 1440
    TITLE = "End Portal"

    STAR_COUNT = 20000
    STAR_BASE_SPEED = 1000
    STAR_MIN_SIZE = 0.01

var
    bus = new EventBus
    screen = initScreen(TITLE, WIDTH, HEIGHT, bus, (0, 5, 0))

var STAR_IMG = screen.loadImage("star.png")

#var textures: array[TexturePtr, 20]



#echo STAR_IMG.texture.repr
#echo STAR_IMG.texture[]

container Stars[STAR_COUNT]:
    type Star = object
        x, y, vx, vy, angle, size: float
        img: Image
        r, g, b, a: uint8


block MAIN:
    var
        star: ptr Star
        id: uint

    echo STAR_COUNT

    for i in 0..STAR_COUNT-1:
        star = Stars.new()
        id = star.table_id

        star.angle = rand(360.0)
        star.size = abs(gauss(0.005, 0.015)) + STAR_MIN_SIZE

        star.vx = -math.sin((star.angle) * math.PI / 180.0) * STAR_BASE_SPEED * star.size
        star.vy = -math.cos((star.angle) * math.PI / 180.0) * STAR_BASE_SPEED * star.size
        star.x = float rand(WIDTH)
        star.y = float rand(HEIGHT)

        star.r = uint8 rand(255.0) * star.size * 5
        star.g = uint8 rand(255.0) * star.size * 10
        star.b = uint8 255
        star.a = uint8 pow(star.size, 1.5) * 7000

        new star.img

        star.img.texture = STAR_IMG.texture
        star.img.w = int (float STAR_IMG.w) * star.size
        star.img.h = int (float STAR_IMG.h) * star.size

        capture id:
            bus.register("draw", proc() =
                var star = Stars[id]
                discard star.img.texture.setTextureAlphaMod(uint8 star.a)
                discard star.img.texture.setTextureColorMod(uint8 star.r, uint8 star.g, uint8 star.b)
                screen.drawRotated(star.img, cint round star.x, cint round star.y, -star.angle))

            bus.register("draw", proc() =
                var star = Stars[id]

                var x = star.x
                var y = star.y

                x += star.vx / screen.real_fps
                y += star.vy / screen.real_fps

                let
                    x_margin = (float STAR_IMG.w) * star.size
                    y_margin = (float STAR_IMG.h) * star.size

                if x > WIDTH + x_margin:
                    x = -x_margin
                elif x < -x_margin:
                    x = WIDTH + x_margin

                if y > HEIGHT + y_margin:
                    y = -y_margin
                elif y < -y_margin:
                    y = HEIGHT + y_margin

                star.x = x
                star.y = y
                )


    #bus.register("draw", proc() = echo screen.real_fps)

    screen.mainloop(120)