import playdate/api

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"
const NIM_IMAGE_PATH = "/images/nim_logo"
const PLAYDATE_NIM_IMAGE_PATH = "/images/playdate_nim"

var font: LCDFont

var playdateNimBitmap: LCDBitmap
var nimLogoBitmap: LCDBitmap

var sprite: LCDSprite

var samplePlayer: SamplePlayer
var filePlayer: FilePlayer

var x = int(LCD_COLUMNS / 2)
var y = int(LCD_ROWS / 2) + 32

proc update(): int =
    # playdate is the global PlaydateAPI instance, available when playdate/api is imported 
    let buttonsState = playdate.system.getButtonsState()
    
    if buttonsState.current.check(kButtonRight):
        x += 10
    if buttonsState.current.check(kButtonLeft):
        x -= 10
    if buttonsState.current.check(kButtonUp):
        y -= 10
    if buttonsState.current.check(kButtonDown):
        y += 10
    
    if buttonsState.pushed.check(kButtonA):
        samplePlayer.play(1, 1.0)
    
    let goalX = x.toFloat
    let goalY = y.toFloat
    let res = sprite.moveWithCollisions(goalX, goalY)
    # + 32 to account for the C SDK ignoring the sprite center point (bug)
    x = (res.actualX + 32).int
    y = (res.actualY + 32).int
    if res.collisions.len > 0:
        # fmt allows the "{variable}" syntax for formatting strings
        playdate.system.logToConsole(fmt"{res.collisions.len} collision(s) occurred!")

    playdate.sprite.drawSprites()
    playdate.system.drawFPS(0, 0)
    playdate.graphics.setDrawMode(kDrawModeNXOR)
    playdate.graphics.drawText("Playdate Nim!", 1, 12)
    playdate.graphics.setDrawMode(kDrawModeCopy)
    playdateNimBitmap.draw(22, 65, kBitmapUnflipped)

    return 1

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) =
    if event == kEventInit:
        playdate.display.setRefreshRate(50)
        # Enables the accelerometer even if it's not used here
        playdate.system.setPeripheralsEnabled(kAllPeripherals)

        samplePlayer = playdate.sound.newSamplePlayer("/audio/jingle")
        filePlayer = playdate.sound.newFilePlayer("/audio/finally_see_the_light")

        filePlayer.play(0)

        # Errors are handled through exceptions
        font = try: playdate.graphics.newFont(FONT_PATH) except: nil
        playdate.graphics.setFont(font)

        playdateNimBitmap = try: playdate.graphics.newBitmap(PLAYDATE_NIM_IMAGE_PATH) except: nil
        nimLogoBitmap = try: playdate.graphics.newBitmap(NIM_IMAGE_PATH) except: nil

        sprite = playdate.sprite.newSprite()
        sprite.add()
        sprite.moveTo(x.float, y.float)
        sprite.setImage(nimLogoBitmap, kBitmapUnflipped)
        sprite.collideRect = PDRect(x: 0, y: 12, width: 64, height: 40)
        # Slide when a collision occurs
        sprite.setCollisionResponseFunction(
            proc(sprite, other: LCDSprite): auto =
                kCollisionTypeSlide
        )

        # Create screen walls 
        let sprite1 = playdate.sprite.newSprite()
        sprite1.add()
        sprite1.moveTo(0, -1)
        sprite1.collideRect = PDRect(x: 0, y: 0, width: 400, height: 1)
        sprite1.collisionsEnabled = true

        let sprite2 = playdate.sprite.newSprite()
        sprite2.add()
        sprite2.moveTo(400, 0)
        sprite2.collideRect = PDRect(x: 0, y: 0, width: 1, height: 240)
        
        let sprite3 = playdate.sprite.newSprite()
        sprite3.add()
        sprite3.moveTo(-1, 0)
        sprite3.collideRect = PDRect(x: 0, y: 0, width: 1, height: 240)
        
        let sprite4 = playdate.sprite.newSprite()
        sprite4.add()
        sprite4.moveTo(0, 240)
        sprite4.collideRect = PDRect(x: 0, y: 0, width: 400, height: 1)

        # Set the update callback
        playdate.system.setUpdateCallback(update)

# Used to setup the SDK entrypoint
initSDK()