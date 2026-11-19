"""
Complete generator for 10 Spot the Difference image pairs (800x600).
Produces 20 PNGs in assets/images/spot_difference/ and outputs JSON metadata.
"""

import os
import json
import math
from PIL import Image, ImageDraw

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "images", "spot_difference")
os.makedirs(OUTPUT_DIR, exist_ok=True)

WIDTH = 800
HEIGHT = 600

def create_gradient_rect(draw, bbox, start_color, end_color):
    x0, y0, x1, y1 = bbox
    height = max(1, y1 - y0)
    for i in range(height):
        t = i / height
        r = int(start_color[0] + (end_color[0] - start_color[0]) * t)
        g = int(start_color[1] + (end_color[1] - start_color[1]) * t)
        b = int(start_color[2] + (end_color[2] - start_color[2]) * t)
        draw.line([(x0, y0 + i), (x1, y0 + i)], fill=(r, g, b))

# ---------------------------------------------------------------------------
# SCENE 1: Cozy Mountain Cabin
# ---------------------------------------------------------------------------
def draw_scene_1(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (15, 23, 42))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 380), (12, 18, 38), (30, 41, 75))

    for sx, sy in [(70, 60), (140, 90), (220, 50), (320, 110), (450, 70), (550, 40), (680, 85), (750, 50), (280, 40), (620, 100)]:
        draw.ellipse([sx-2, sy-2, sx+2, sy+2], fill=(254, 240, 138))

    draw.ellipse([640, 50, 700, 110], fill=(254, 240, 138))
    draw.ellipse([655, 45, 715, 105], fill=(15, 23, 42))

    draw.polygon([(0, 380), (180, 160), (350, 380)], fill=(40, 53, 90))
    draw.polygon([(180, 160), (150, 200), (180, 220), (210, 200)], fill=(226, 232, 240))
    draw.polygon([(250, 380), (460, 130), (660, 380)], fill=(32, 44, 76))
    draw.polygon([(460, 130), (420, 180), (460, 200), (500, 180)], fill=(241, 245, 249))

    draw.ellipse([-50, 340, 450, 650], fill=(203, 213, 225))
    draw.ellipse([300, 330, 850, 680], fill=(226, 232, 240))
    draw.rectangle([0, 420, WIDTH, HEIGHT], fill=(241, 245, 249))

    draw.rectangle([123, 380, 137, 450], fill=(69, 45, 28))
    draw.polygon([(70, 420), (130, 310), (190, 420)], fill=(20, 83, 45))
    draw.polygon([(85, 360), (130, 270), (175, 360)], fill=(22, 101, 52))
    draw.polygon([(95, 310), (130, 230), (165, 310)], fill=(21, 128, 61))

    # Diff 3: Snow cap on pine tree (x: 130, y: 270) -> norm (0.163, 0.450)
    if not is_b:
        draw.polygon([(110, 270), (130, 230), (150, 270)], fill=(255, 255, 255))
        draw.polygon([(100, 320), (130, 290), (160, 320)], fill=(255, 255, 255))

    draw.polygon([(690, 450), (730, 360), (770, 450)], fill=(22, 101, 52))
    draw.polygon([(705, 400), (730, 320), (755, 400)], fill=(34, 197, 94))

    draw.rectangle([300, 290, 560, 460], fill=(120, 53, 15))
    for ly in range(310, 460, 20):
        draw.line([(300, ly), (560, ly)], fill=(90, 40, 10), width=2)

    draw.polygon([(270, 295), (430, 190), (590, 295)], fill=(71, 85, 105))
    draw.polygon([(260, 300), (430, 185), (600, 300)], fill=(148, 163, 184), outline=(203, 213, 225))

    draw.rectangle([515, 180, 545, 260], fill=(100, 116, 139))
    draw.rectangle([510, 175, 550, 185], fill=(71, 85, 105))

    # Diff 1: Chimney smoke (x: 575, y: 120) -> norm (0.719, 0.200)
    if not is_b:
        draw.ellipse([535, 140, 565, 165], fill=(226, 232, 240))
        draw.ellipse([555, 110, 595, 140], fill=(203, 213, 225))
        draw.ellipse([570, 80, 615, 115], fill=(148, 163, 184))

    draw.rectangle([415, 350, 465, 460], fill=(69, 26, 3))
    draw.ellipse([455, 405, 461, 411], fill=(234, 179, 8))

    draw.rectangle([330, 350, 385, 410], fill=(254, 240, 138), outline=(69, 26, 3), width=3)
    draw.line([(357, 350), (357, 410)], fill=(69, 26, 3), width=2)
    draw.line([(330, 380), (385, 380)], fill=(69, 26, 3), width=2)

    # Diff 2: Dormer window light (x: 430, y: 258) -> norm (0.538, 0.430)
    w_fill = (30, 41, 59) if is_b else (250, 204, 21)
    draw.rectangle([410, 235, 450, 280], fill=w_fill, outline=(69, 26, 3), width=3)
    draw.line([(430, 235), (430, 280)], fill=(69, 26, 3), width=2)
    draw.line([(410, 257), (450, 257)], fill=(69, 26, 3), width=2)

    # Diff 4: Porch lantern (x: 495, y: 405) -> norm (0.619, 0.675)
    if not is_b:
        draw.line([(485, 395), (495, 395)], fill=(15, 23, 42), width=3)
        draw.rectangle([490, 395, 502, 415], fill=(250, 204, 21), outline=(15, 23, 42), width=2)
        draw.polygon([(488, 395), (496, 388), (504, 395)], fill=(15, 23, 42))

    for stx, sty in [(440, 475), (425, 510), (450, 545), (430, 580)]:
        draw.ellipse([stx-18, sty-8, stx+18, sty+8], fill=(148, 163, 184))

    return img

# ---------------------------------------------------------------------------
# SCENE 2: Orbital Space Station
# ---------------------------------------------------------------------------
def draw_scene_2(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (5, 7, 20))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, HEIGHT), (3, 7, 18), (15, 23, 42))

    # Earth curve at bottom
    draw.ellipse([-100, 480, 900, 900], fill=(14, 116, 144))
    draw.ellipse([-80, 490, 880, 890], fill=(2, 132, 199))
    draw.ellipse([-50, 510, 850, 870], fill=(12, 74, 110))

    # Stars
    for sx, sy in [(50, 80), (120, 150), (200, 40), (280, 110), (380, 50), (520, 90), (600, 30), (740, 120), (770, 200), (90, 280)]:
        draw.ellipse([sx-2, sy-2, sx+2, sy+2], fill=(255, 255, 255))

    # Diff 3: Distant spiral galaxy (x: 670, y: 90) -> norm (0.838, 0.150)
    if not is_b:
        draw.ellipse([650, 75, 690, 105], outline=(147, 197, 253), width=2)
        draw.ellipse([655, 80, 685, 100], fill=(192, 132, 252))

    # Station Central Truss
    draw.rectangle([180, 250, 620, 270], fill=(148, 163, 184), outline=(100, 116, 139), width=2)

    # Solar Arrays - Left
    draw.rectangle([100, 180, 170, 340], fill=(30, 58, 138), outline=(59, 130, 246), width=2)
    for ly in range(200, 340, 20):
        draw.line([(100, ly), (170, ly)], fill=(96, 165, 250))
    draw.line([(135, 180), (135, 340)], fill=(96, 165, 250))

    # Solar Arrays - Right
    draw.rectangle([630, 180, 700, 340], fill=(30, 58, 138), outline=(59, 130, 246), width=2)
    for ly in range(200, 340, 20):
        draw.line([(630, ly), (700, ly)], fill=(96, 165, 250))
    draw.line([(665, 180), (665, 340)], fill=(96, 165, 250))

    # Diff 2: Telemetry status bar on right solar array (x: 655, y: 260) -> norm (0.819, 0.433)
    if not is_b:
        draw.rectangle([645, 255, 685, 265], fill=(34, 197, 94)) # glowing green LED
    else:
        draw.rectangle([645, 255, 685, 265], fill=(15, 23, 42))

    # Central Habitat Module (Cylinder + Cupola)
    draw.rectangle([350, 210, 450, 310], fill=(226, 232, 240), outline=(148, 163, 184), width=3)
    draw.ellipse([375, 235, 425, 285], fill=(15, 23, 42), outline=(56, 189, 248), width=3)
    draw.ellipse([385, 245, 415, 275], fill=(56, 189, 248)) # blue observation dome

    # Spire / Communications Tower
    draw.line([(400, 210), (400, 130)], fill=(203, 213, 225), width=4)

    # Diff 1: Satellite Dish on spire (x: 400, y: 110) -> norm (0.500, 0.183)
    if not is_b:
        draw.arc([370, 90, 430, 135], start=200, end=340, fill=(248, 250, 252), width=5)
        draw.line([(400, 110), (415, 95)], fill=(239, 68, 68), width=2)

    # Diff 4: Docked Scout Shuttle (x: 160, y: 290) -> norm (0.200, 0.483)
    if not is_b:
        draw.polygon([(140, 290), (170, 275), (170, 305)], fill=(241, 245, 249), outline=(71, 85, 105), width=2)
        draw.ellipse([155, 285, 165, 295], fill=(56, 189, 248)) # cockpit glass

    # Radiator panels
    draw.rectangle([480, 235, 540, 285], fill=(203, 213, 225), outline=(100, 116, 139), width=2)
    draw.line([(480, 260), (540, 260)], fill=(148, 163, 184))

    return img

# ---------------------------------------------------------------------------
# SCENE 3: Enchanted Forest
# ---------------------------------------------------------------------------
def draw_scene_3(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (6, 78, 59))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 400), (4, 47, 46), (19, 78, 74))
    create_gradient_rect(draw, (0, 380, WIDTH, HEIGHT), (20, 83, 45), (15, 23, 42))

    # Sunbeams
    for bx in [200, 350, 500]:
        draw.polygon([(bx, 0), (bx+60, 0), (bx+180, HEIGHT), (bx+80, HEIGHT)], fill=(20, 184, 166))

    # Ancient Tree Trunk
    draw.polygon([(360, 600), (390, 220), (450, 220), (480, 600)], fill=(69, 45, 28))
    # Branches
    draw.line([(400, 300), (280, 180)], fill=(69, 45, 28), width=18)
    draw.line([(440, 280), (560, 170)], fill=(69, 45, 28), width=16)

    # Canopy Leaves
    draw.ellipse([200, 80, 420, 220], fill=(16, 185, 129))
    draw.ellipse([420, 70, 640, 210], fill=(5, 150, 105))
    draw.ellipse([300, 40, 520, 180], fill=(52, 211, 153))

    # River / Stream
    draw.polygon([(0, 460), (180, 420), (350, 500), (500, 600), (0, 600)], fill=(14, 165, 233))
    draw.line([(20, 500), (180, 450)], fill=(224, 242, 254), width=3)
    draw.line([(150, 520), (320, 530)], fill=(224, 242, 254), width=3)

    # Diff 4: Hanging Willow Lantern (x: 290, y: 170) -> norm (0.363, 0.283)
    if not is_b:
        draw.line([(290, 140), (290, 170)], fill=(120, 53, 15), width=2)
        draw.ellipse([275, 170, 305, 205], fill=(250, 204, 21), outline=(120, 53, 15), width=2)

    # Diff 2: Glowing cyan tree rune (x: 400, y: 290) -> norm (0.500, 0.483)
    if not is_b:
        draw.ellipse([405, 340, 435, 370], outline=(34, 211, 238), width=3)
        draw.line([(420, 335), (420, 375)], fill=(34, 211, 238), width=3)
        draw.line([(405, 355), (435, 355)], fill=(34, 211, 238), width=3)

    # Diff 1: Giant glowing mushrooms (x: 180, y: 460) -> norm (0.225, 0.767)
    draw.rectangle([170, 460, 185, 495], fill=(226, 232, 240))
    draw.ellipse([150, 440, 205, 470], fill=(168, 85, 247)) # Purple cap 1
    if not is_b:
        draw.rectangle([195, 470, 205, 500], fill=(226, 232, 240))
        draw.ellipse([180, 455, 220, 480], fill=(217, 70, 239)) # Purple cap 2 (present in A, absent in B)

    # Moss Rock on right bank
    draw.ellipse([580, 480, 690, 550], fill=(71, 85, 105))
    draw.arc([590, 485, 680, 520], 180, 360, fill=(34, 197, 94), width=6)

    # Diff 3: Blue butterfly on rock (x: 625, y: 490) -> norm (0.781, 0.817)
    if not is_b:
        draw.polygon([(615, 480), (625, 490), (615, 500)], fill=(59, 130, 246))
        draw.polygon([(635, 480), (625, 490), (635, 500)], fill=(59, 130, 246))
        draw.line([(625, 480), (625, 500)], fill=(15, 23, 42), width=2)

    return img

# ---------------------------------------------------------------------------
# SCENE 4: Underwater Coral Reef
# ---------------------------------------------------------------------------
def draw_scene_4(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (8, 145, 178))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 480), (6, 182, 212), (14, 116, 144))
    create_gradient_rect(draw, (0, 480, WIDTH, HEIGHT), (250, 204, 21), (202, 138, 4)) # sand floor

    # Coral formations
    draw.ellipse([30, 360, 180, 520], fill=(244, 63, 94))
    draw.ellipse([80, 320, 200, 460], fill=(251, 113, 133))
    draw.ellipse([620, 340, 780, 520], fill=(168, 85, 247))
    draw.ellipse([660, 380, 770, 540], fill=(192, 132, 252))

    # Sea Turtle
    draw.ellipse([290, 180, 380, 240], fill=(16, 185, 129), outline=(4, 120, 87), width=3)
    draw.ellipse([380, 195, 415, 225], fill=(52, 211, 153)) # Head
    draw.polygon([(340, 175), (370, 135), (355, 180)], fill=(16, 185, 129)) # Flipper
    draw.polygon([(340, 245), (370, 285), (355, 240)], fill=(16, 185, 129)) # Flipper

    # Diff 2: Sea turtle carapace pattern (x: 335, y: 210) -> norm (0.419, 0.350)
    if not is_b:
        draw.ellipse([315, 195, 355, 225], fill=(245, 158, 11), outline=(180, 83, 9), width=2)
        draw.line([(315, 210), (355, 210)], fill=(180, 83, 9), width=2)

    # Diff 4: Striped Yellow Tang fish (x: 145, y: 250) -> norm (0.181, 0.417)
    if not is_b:
        draw.polygon([(120, 240), (160, 220), (160, 260)], fill=(250, 204, 21))
        draw.polygon([(160, 240), (175, 225), (175, 255)], fill=(234, 179, 8))
        draw.line([(140, 225), (140, 255)], fill=(30, 41, 59), width=3) # Black stripe

    # Diff 3: Air bubble column (x: 545, y: 180) -> norm (0.681, 0.300)
    if not is_b:
        for bx, by, br in [(545, 240, 8), (550, 200, 12), (542, 160, 10), (548, 120, 14)]:
            draw.ellipse([bx-br, by-br, bx+br, by+br], fill=(224, 242, 254), outline=(255, 255, 255), width=2)

    # Diff 1: Starfish on bottom right sand (x: 655, y: 515) -> norm (0.819, 0.858)
    if not is_b:
        cx, cy = 655, 515
        points = []
        for i in range(10):
            r = 22 if i % 2 == 0 else 9
            angle = i * math.pi / 5 - math.pi / 2
            points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
        draw.polygon(points, fill=(249, 115, 22), outline=(194, 65, 12))

    return img

# ---------------------------------------------------------------------------
# SCENE 5: Zen Sanctuary Garden
# ---------------------------------------------------------------------------
def draw_scene_5(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (241, 245, 249))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 320), (224, 231, 255), (254, 242, 242)) # morning misty sky
    create_gradient_rect(draw, (0, 320, WIDTH, HEIGHT), (226, 232, 240), (203, 213, 225)) # raked sand floor

    # Bamboo fence
    for bx in range(0, WIDTH, 28):
        draw.rectangle([bx, 240, bx+16, 340], fill=(202, 138, 4), outline=(161, 98, 7), width=1)
    draw.line([(0, 270), (WIDTH, 270)], fill=(161, 98, 7), width=4)

    # Pond
    draw.ellipse([500, 380, 780, 560], fill=(56, 189, 248), outline=(148, 163, 184), width=6)
    # Lily pad
    draw.ellipse([540, 420, 590, 450], fill=(34, 197, 94))

    # Diff 1: Koi fish in pond (x: 600, y: 445) -> norm (0.750, 0.742)
    if not is_b:
        draw.ellipse([580, 435, 620, 455], fill=(239, 68, 68))
        draw.polygon([(575, 445), (560, 435), (560, 455)], fill=(248, 113, 113))
        draw.ellipse([595, 440, 605, 450], fill=(255, 255, 255))

    # Stone Pagoda Lantern
    draw.rectangle([220, 280, 260, 360], fill=(148, 163, 184), outline=(100, 116, 139), width=2)
    draw.polygon([(200, 280), (240, 240), (280, 280)], fill=(100, 116, 139)) # roof

    # Diff 2: Pagoda Roof Finial Jewel (x: 240, y: 230) -> norm (0.300, 0.383)
    if not is_b:
        draw.ellipse([232, 218, 248, 238], fill=(234, 179, 8), outline=(161, 98, 7), width=2)

    # Cherry blossom tree branch from upper right
    draw.line([(WIDTH, 80), (600, 130), (520, 160)], fill=(120, 53, 15), width=12)
    draw.line([(600, 130), (550, 90)], fill=(120, 53, 15), width=8)

    for px, py in [(620, 110), (580, 140), (640, 90), (530, 150)]:
        draw.ellipse([px-14, py-14, px+14, py+14], fill=(244, 114, 182))

    # Diff 3: Dense blossom branch cluster (x: 530, y: 145) -> norm (0.663, 0.242)
    if not is_b:
        draw.ellipse([505, 130, 545, 170], fill=(236, 72, 153))
        draw.ellipse([490, 140, 520, 170], fill=(244, 114, 182))

    # Diff 4: Raked gravel concentric ring around meditation stone (x: 370, y: 470) -> norm (0.463, 0.783)
    if not is_b:
        draw.ellipse([310, 420, 430, 520], outline=(148, 163, 184), width=3)
        draw.ellipse([325, 435, 415, 505], outline=(148, 163, 184), width=2)
    # Center Stone
    draw.ellipse([345, 450, 395, 490], fill=(71, 85, 105))

    return img

# ---------------------------------------------------------------------------
# SCENE 6: Sunset City Rooftop
# ---------------------------------------------------------------------------
def draw_scene_6(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (254, 215, 170))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 360), (239, 68, 68), (251, 191, 36)) # Sunset sky

    # Skyline Buildings
    draw.rectangle([60, 180, 170, 380], fill=(51, 65, 85))
    draw.rectangle([190, 120, 310, 380], fill=(30, 41, 59))
    draw.rectangle([340, 200, 450, 380], fill=(71, 85, 105))
    draw.rectangle([480, 150, 600, 380], fill=(30, 41, 59))
    draw.rectangle([630, 100, 740, 380], fill=(15, 23, 42))

    # Yellow window grids
    for wy in range(140, 360, 30):
        draw.rectangle([210, wy, 235, wy+15], fill=(254, 240, 138))
        draw.rectangle([260, wy, 285, wy+15], fill=(254, 240, 138))

    # Diff 3: Airship / Blimp in sky (x: 510, y: 110) -> norm (0.638, 0.183)
    if not is_b:
        draw.ellipse([470, 95, 550, 125], fill=(226, 232, 240), outline=(71, 85, 105), width=2)
        draw.polygon([(460, 105), (475, 100), (475, 120)], fill=(239, 68, 68)) # rudder

    # Rooftop Terrace Deck
    create_gradient_rect(draw, (0, 360, WIDTH, HEIGHT), (120, 53, 15), (69, 26, 3)) # wood planks
    for px in range(0, WIDTH, 40):
        draw.line([(px, 360), (px, HEIGHT)], fill=(69, 26, 3), width=2)

    # Parapet brick wall on right
    draw.rectangle([620, 330, WIDTH, 420], fill=(185, 28, 28), outline=(127, 29, 29), width=2)

    # Diff 1: Cat sitting on wall (x: 680, y: 350) -> norm (0.850, 0.583)
    if not is_b:
        draw.ellipse([665, 335, 695, 365], fill=(249, 115, 22)) # body
        draw.ellipse([670, 320, 690, 340], fill=(249, 115, 22)) # head
        draw.polygon([(670, 325), (675, 310), (680, 325)], fill=(249, 115, 22)) # ear
        draw.polygon([(682, 325), (687, 310), (692, 325)], fill=(249, 115, 22)) # ear

    # Diff 2: Telescope on tripod (x: 210, y: 370) -> norm (0.263, 0.617)
    draw.line([(210, 370), (180, 450)], fill=(203, 213, 225), width=4)
    draw.line([(210, 370), (240, 450)], fill=(203, 213, 225), width=4)
    draw.line([(210, 370), (210, 450)], fill=(203, 213, 225), width=4)
    if not is_b:
        # Telescope optical barrel
        draw.polygon([(180, 390), (250, 340), (260, 355), (190, 405)], fill=(245, 158, 11), outline=(180, 83, 9), width=2)

    # String lights from left to right
    draw.arc([100, 180, 600, 280], 0, 180, fill=(30, 41, 59), width=2)
    # Diff 4: Central string light bulbs (x: 380, y: 210) -> norm (0.475, 0.350)
    for bx, by in [(220, 225), (320, 230), (380, 225), (480, 215)]:
        if is_b and bx in [320, 380]:
            draw.ellipse([bx-6, by-6, bx+6, by+6], fill=(71, 85, 105)) # turned off
        else:
            draw.ellipse([bx-6, by-6, bx+6, by+6], fill=(254, 240, 138), outline=(234, 179, 8), width=1)

    return img

# ---------------------------------------------------------------------------
# SCENE 7: Artist Loft Studio
# ---------------------------------------------------------------------------
def draw_scene_7(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (248, 250, 252))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 400), (241, 245, 249), (226, 232, 240)) # loft wall
    create_gradient_rect(draw, (0, 400, WIDTH, HEIGHT), (180, 83, 9), (120, 53, 15)) # studio floor

    # Large Arched Window on left
    draw.rectangle([60, 80, 220, 340], fill=(186, 230, 253), outline=(71, 85, 105), width=6)
    draw.arc([60, 40, 220, 160], 180, 360, fill=(71, 85, 105), width=6)
    draw.line([(140, 40), (140, 340)], fill=(71, 85, 105), width=3)
    draw.line([(60, 200), (220, 200)], fill=(71, 85, 105), width=3)

    # Diff 4: Sunflower in vase on window sill (x: 130, y: 215) -> norm (0.163, 0.358)
    draw.rectangle([115, 300, 145, 340], fill=(234, 88, 12)) # vase
    if not is_b:
        draw.line([(130, 300), (130, 220)], fill=(34, 197, 94), width=4)
        draw.ellipse([110, 200, 150, 240], fill=(234, 179, 8))
        draw.ellipse([120, 210, 140, 230], fill=(120, 53, 15)) # flower center

    # Wooden Easel in Center
    draw.line([(420, 180), (360, 520)], fill=(120, 53, 15), width=6)
    draw.line([(420, 180), (480, 520)], fill=(120, 53, 15), width=6)
    draw.line([(420, 180), (420, 500)], fill=(146, 64, 14), width=5)

    # Canvas on Easel
    draw.rectangle([360, 200, 480, 320], fill=(255, 255, 255), outline=(120, 53, 15), width=4)
    # Painting inside canvas (mountain landscape)
    draw.polygon([(365, 315), (410, 250), (450, 315)], fill=(34, 197, 94))
    draw.polygon([(430, 315), (460, 270), (475, 315)], fill=(22, 101, 52))

    # Diff 3: Golden sun in easel canvas painting (x: 415, y: 250) -> norm (0.519, 0.417)
    if not is_b:
        draw.ellipse([405, 215, 435, 245], fill=(245, 158, 11))

    # Paint Stool with Palette
    draw.rectangle([250, 420, 310, 480], fill=(180, 83, 9))
    draw.ellipse([240, 410, 320, 450], fill=(254, 243, 199), outline=(120, 53, 15), width=2)
    draw.ellipse([260, 425, 275, 435], fill=(59, 130, 246)) # blue blob
    draw.ellipse([285, 425, 300, 435], fill=(34, 197, 94)) # green blob

    # Diff 2: Red paint dollop on palette (x: 275, y: 455) -> norm (0.344, 0.758)
    if not is_b:
        draw.ellipse([270, 435, 285, 445], fill=(239, 68, 68)) # red paint

    # Wall Clock on Right Wall
    draw.ellipse([610, 90, 670, 150], fill=(255, 255, 255), outline=(30, 41, 59), width=4)
    draw.ellipse([637, 117, 643, 123], fill=(30, 41, 59))
    # Diff 1: Clock hands (3:00 vs 9:00) (x: 640, y: 120) -> norm (0.800, 0.200)
    draw.line([(640, 120), (640, 100)], fill=(30, 41, 59), width=2) # minute hand up
    if not is_b:
        draw.line([(640, 120), (660, 120)], fill=(239, 68, 68), width=3) # 3:00
    else:
        draw.line([(640, 120), (620, 120)], fill=(239, 68, 68), width=3) # 9:00

    return img

# ---------------------------------------------------------------------------
# SCENE 8: Morning Bakery Cafe
# ---------------------------------------------------------------------------
def draw_scene_8(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (255, 247, 237))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 320), (254, 243, 199), (255, 237, 213))
    create_gradient_rect(draw, (0, 320, WIDTH, HEIGHT), (148, 163, 184), (71, 85, 105)) # pavement

    # Shop Window Frame
    draw.rectangle([80, 120, 720, 360], fill=(255, 255, 255), outline=(120, 53, 15), width=8)

    # Awning Stripes
    for ax, color in [(80, (239, 68, 68)), (160, (255, 255, 255)), (240, (239, 68, 68)), (320, (255, 255, 255)),
                      (400, (239, 68, 68)), (480, (255, 255, 255)), (560, (239, 68, 68)), (640, (255, 255, 255))]:
        # Diff 3: Awning section color (x: 225, y: 90) -> norm (0.281, 0.150)
        c = (59, 130, 246) if (is_b and ax == 240) else color
        draw.rectangle([ax, 60, ax+80, 130], fill=c, outline=(120, 53, 15), width=2)

    # Glass display counter inside window
    draw.rectangle([200, 230, 600, 350], fill=(254, 240, 138), outline=(180, 83, 9), width=3)

    # Cakes on display
    draw.ellipse([370, 280, 430, 310], fill=(254, 205, 211), outline=(244, 63, 94), width=2) # Central cake
    # Diff 1: Strawberry topper on cake (x: 400, y: 395? wait: y is 275) -> norm (0.500, 0.458)
    if not is_b:
        draw.polygon([(395, 275), (405, 275), (400, 260)], fill=(225, 29, 72))

    # Bistro Table on right
    draw.ellipse([550, 380, 670, 440], fill=(226, 232, 240), outline=(100, 116, 139), width=3)
    draw.line([(610, 440), (610, 540)], fill=(71, 85, 105), width=6)
    draw.rectangle([585, 370, 610, 395], fill=(245, 158, 11)) # Coffee mug

    # Diff 2: Steam swirls from coffee mug (x: 595, y: 340) -> norm (0.744, 0.567)
    if not is_b:
        draw.arc([588, 330, 602, 365], 270, 90, fill=(148, 163, 184), width=3)
        draw.arc([595, 320, 609, 355], 90, 270, fill=(148, 163, 184), width=3)

    # Diff 4: Potted Lavender on sidewalk left (x: 100, y: 470) -> norm (0.125, 0.783)
    draw.rectangle([80, 470, 120, 520], fill=(180, 83, 9)) # terracotta pot
    if not is_b:
        for lx in [90, 100, 110]:
            draw.line([(lx, 470), (lx, 430)], fill=(34, 197, 94), width=2)
            draw.ellipse([lx-5, 415, lx+5, 435], fill=(168, 85, 247))

    return img

# ---------------------------------------------------------------------------
# SCENE 9: Ancient Library Nook
# ---------------------------------------------------------------------------
def draw_scene_9(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (41, 37, 36))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, HEIGHT), (28, 25, 23), (68, 64, 60))

    # Grand Bookshelf
    draw.rectangle([200, 60, 750, 450], fill=(120, 53, 15), outline=(69, 26, 3), width=6)
    # Shelves
    for sy in [150, 250, 350]:
        draw.line([(200, sy), (750, sy)], fill=(69, 26, 3), width=8)

    # Books row 1
    colors = [(239, 68, 68), (59, 130, 246), (34, 197, 94), (234, 179, 8), (168, 85, 247)]
    for i, bx in enumerate(range(220, 400, 22)):
        c = colors[i % len(colors)]
        draw.rectangle([bx, 80, bx+18, 146], fill=c, outline=(30, 41, 59), width=1)

    # Diff 2: Red Ribbon bookmark on top shelf book (x: 255, y: 130) -> norm (0.319, 0.217)
    if not is_b:
        draw.polygon([(252, 146), (258, 146), (255, 170)], fill=(239, 68, 68))

    # Reading Desk
    draw.rectangle([350, 400, 720, 560], fill=(180, 83, 9), outline=(120, 53, 15), width=4)

    # Banker's Lamp
    draw.line([(540, 400), (540, 340)], fill=(234, 179, 8), width=5) # brass neck
    # Diff 1: Lamp shade glowing green vs dark (x: 540, y: 350) -> norm (0.675, 0.583)
    lamp_color = (34, 197, 94) if not is_b else (20, 83, 45)
    draw.ellipse([510, 335, 570, 365], fill=lamp_color, outline=(234, 179, 8), width=2)
    if not is_b:
        draw.ellipse([495, 340, 585, 410], fill=(254, 240, 138, 50)) # warm halo

    # Diff 3: Globe on pedestal on right side of desk (x: 655, y: 370) -> norm (0.819, 0.617)
    draw.line([(655, 400), (655, 370)], fill=(234, 179, 8), width=4) # base
    draw.arc([635, 345, 675, 395], 0, 180, fill=(234, 179, 8), width=3) # meridian
    if not is_b:
        draw.ellipse([640, 350, 670, 380], fill=(59, 130, 246), outline=(34, 197, 94), width=2) # globe sphere

    # Gothic Stained Glass Window on Left
    draw.rectangle([40, 100, 160, 320], fill=(30, 58, 138), outline=(148, 163, 184), width=4)
    draw.arc([40, 40, 160, 160], 180, 360, fill=(148, 163, 184), width=4)
    # Diff 4: Star Crest in window (x: 100, y: 180) -> norm (0.125, 0.300)
    if not is_b:
        draw.ellipse([85, 165, 115, 195], fill=(234, 179, 8), outline=(245, 158, 11), width=2)

    return img

# ---------------------------------------------------------------------------
# SCENE 10: Futuristic Science Lab
# ---------------------------------------------------------------------------
def draw_scene_10(is_b=False):
    img = Image.new("RGB", (WIDTH, HEIGHT), (15, 23, 42))
    draw = ImageDraw.Draw(img)
    create_gradient_rect(draw, (0, 0, WIDTH, 380), (15, 23, 42), (30, 41, 59))
    create_gradient_rect(draw, (0, 380, WIDTH, HEIGHT), (51, 65, 85), (30, 41, 59))

    # Lab Bench
    draw.rectangle([100, 360, 720, 520], fill=(226, 232, 240), outline=(148, 163, 184), width=3)

    # Diff 4: Molecular model hanging from ceiling (x: 415, y: 110) -> norm (0.519, 0.183)
    draw.line([(415, 0), (415, 90)], fill=(148, 163, 184), width=2)
    draw.ellipse([405, 90, 425, 110], fill=(59, 130, 246)) # atom 1
    draw.line([(415, 100), (445, 120)], fill=(148, 163, 184), width=2)
    draw.ellipse([435, 110, 455, 130], fill=(239, 68, 68)) # atom 2
    if not is_b:
        draw.line([(415, 100), (385, 120)], fill=(148, 163, 184), width=2)
        draw.ellipse([375, 110, 395, 130], fill=(34, 197, 94)) # atom 3 (present in A, absent in B)

    # Distillation Flask & Chemistry Stand
    draw.line([(300, 280), (300, 400)], fill=(100, 116, 139), width=4) # clamp rod
    draw.line([(300, 330), (330, 330)], fill=(100, 116, 139), width=3)
    # Diff 1: Liquid in flask (x: 305, y: 370) -> norm (0.381, 0.617)
    draw.ellipse([285, 345, 325, 385], outline=(148, 163, 184), width=2)
    if not is_b:
        draw.ellipse([290, 355, 320, 380], fill=(34, 211, 238)) # glowing cyan reagent

    # Microscope
    draw.rectangle([170, 370, 205, 410], fill=(71, 85, 105)) # base
    draw.line([(180, 370), (180, 320)], fill=(71, 85, 105), width=6)
    draw.line([(180, 320), (200, 335)], fill=(148, 163, 184), width=8) # lens barrel
    # Diff 3: Specimen Slide Glow (x: 175, y: 410) -> norm (0.219, 0.683)
    if not is_b:
        draw.rectangle([165, 395, 195, 405], fill=(163, 230, 53), outline=(101, 163, 13), width=1) # glowing green specimen

    # Digital Oscilloscope Monitor
    draw.rectangle([520, 180, 630, 260], fill=(15, 23, 42), outline=(100, 116, 139), width=3)
    # Diff 2: Waveform on monitor (x: 575, y: 220) -> norm (0.719, 0.367)
    if not is_b:
        points = []
        for i in range(530, 620, 5):
            y = 220 + 20 * math.sin((i - 530) * 0.15)
            points.append((i, y))
        draw.line(points, fill=(34, 197, 94), width=2) # Sine wave
    else:
        draw.line([(530, 220), (620, 220)], fill=(239, 68, 68), width=2) # Flatline

    return img


METADATA = [
    {
        "id": "challenge_01",
        "title": "Cozy Mountain Cabin",
        "themeTag": "Alpine Winter",
        "difficulty": "easy",
        "description": "Inspect this peaceful winter cabin under the night stars.",
        "imageAssetA": "assets/images/spot_difference/challenge_01_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_01_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c1_d1", "description": "Smoke puff rising from the stone chimney", "x": 0.719, "y": 0.200, "radius": 0.08},
            {"id": "c1_d2", "description": "Upstairs dormer window warm light", "x": 0.538, "y": 0.430, "radius": 0.07},
            {"id": "c1_d3", "description": "Snow cap on tall pine tree peak", "x": 0.163, "y": 0.450, "radius": 0.08},
            {"id": "c1_d4", "description": "Hanging porch lantern beside doorway", "x": 0.619, "y": 0.675, "radius": 0.06}
        ]
    },
    {
        "id": "challenge_02",
        "title": "Orbital Space Station",
        "themeTag": "Deep Space Sci-Fi",
        "difficulty": "medium",
        "description": "Examine this research outpost in low Earth orbit.",
        "imageAssetA": "assets/images/spot_difference/challenge_02_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_02_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c2_d1", "description": "Communications satellite dish on spire", "x": 0.500, "y": 0.183, "radius": 0.07},
            {"id": "c2_d2", "description": "Green telemetry status indicator on solar wing", "x": 0.819, "y": 0.433, "radius": 0.06},
            {"id": "c2_d3", "description": "Distant purple spiral galaxy in upper right", "x": 0.838, "y": 0.150, "radius": 0.06},
            {"id": "c2_d4", "description": "Scout shuttle craft docked on left airlock", "x": 0.200, "y": 0.483, "radius": 0.08}
        ]
    },
    {
        "id": "challenge_03",
        "title": "Enchanted Forest",
        "themeTag": "Fantasy Woodland",
        "difficulty": "medium",
        "description": "Discover magical anomalies hidden among ancient roots.",
        "imageAssetA": "assets/images/spot_difference/challenge_03_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_03_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c3_d1", "description": "Cluster of glowing purple mushrooms on riverbank", "x": 0.225, "y": 0.767, "radius": 0.07},
            {"id": "c3_d2", "description": "Glowing cyan magical rune carved into ancient trunk", "x": 0.500, "y": 0.483, "radius": 0.06},
            {"id": "c3_d3", "description": "Blue butterfly resting on mossy river stone", "x": 0.781, "y": 0.817, "radius": 0.06},
            {"id": "c3_d4", "description": "Hanging golden willow lantern on branch", "x": 0.363, "y": 0.283, "radius": 0.07}
        ]
    },
    {
        "id": "challenge_04",
        "title": "Underwater Coral Reef",
        "themeTag": "Ocean Marine",
        "difficulty": "easy",
        "description": "Spot subtle marine variations in this colorful coral haven.",
        "imageAssetA": "assets/images/spot_difference/challenge_04_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_04_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c4_d1", "description": "Orange sea star on the sandy ocean floor", "x": 0.819, "y": 0.858, "radius": 0.07},
            {"id": "c4_d2", "description": "Golden shell geometric scutes on turtle carapace", "x": 0.419, "y": 0.350, "radius": 0.08},
            {"id": "c4_d3", "description": "Stream of air bubbles ascending from coral reef", "x": 0.681, "y": 0.300, "radius": 0.06},
            {"id": "c4_d4", "description": "Striped yellow tang swimming near left reef", "x": 0.181, "y": 0.417, "radius": 0.07}
        ]
    },
    {
        "id": "challenge_05",
        "title": "Zen Sanctuary Garden",
        "themeTag": "Japanese Harmony",
        "difficulty": "easy",
        "description": "Look for peace and subtle shifts in this raked gravel sanctuary.",
        "imageAssetA": "assets/images/spot_difference/challenge_05_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_05_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c5_d1", "description": "Red and white koi fish swimming in garden pond", "x": 0.750, "y": 0.742, "radius": 0.07},
            {"id": "c5_d2", "description": "Stone pagoda lantern top finial jewel", "x": 0.300, "y": 0.383, "radius": 0.06},
            {"id": "c5_d3", "description": "Dense pink cherry blossom cluster on branch", "x": 0.663, "y": 0.242, "radius": 0.08},
            {"id": "c5_d4", "description": "Concentric raked gravel rings around meditation rock", "x": 0.463, "y": 0.783, "radius": 0.08}
        ]
    },
    {
        "id": "challenge_06",
        "title": "Sunset City Rooftop",
        "themeTag": "Urban Evening",
        "difficulty": "medium",
        "description": "Scan this twilight skyscraper terrace overlooking the city.",
        "imageAssetA": "assets/images/spot_difference/challenge_06_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_06_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c6_d1", "description": "Ginger tabby cat perched on brick parapet wall", "x": 0.850, "y": 0.583, "radius": 0.07},
            {"id": "c6_d2", "description": "Brass telescope optical tube mounted on tripod", "x": 0.263, "y": 0.617, "radius": 0.08},
            {"id": "c6_d3", "description": "Distant airship cruising across the sunset sky", "x": 0.638, "y": 0.183, "radius": 0.07},
            {"id": "c6_d4", "description": "Illuminated warm fairy lights along the patio cord", "x": 0.475, "y": 0.350, "radius": 0.06}
        ]
    },
    {
        "id": "challenge_07",
        "title": "Artist Loft Studio",
        "themeTag": "Creative Atelier",
        "difficulty": "medium",
        "description": "Scrutinize this sunlit creative workspace and painting easel.",
        "imageAssetA": "assets/images/spot_difference/challenge_07_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_07_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c7_d1", "description": "Studio wall clock hands orientation", "x": 0.800, "y": 0.200, "radius": 0.06},
            {"id": "c7_d2", "description": "Crimson oil paint dollop on wooden palette", "x": 0.344, "y": 0.758, "radius": 0.06},
            {"id": "c7_d3", "description": "Golden sun illustration on the easel landscape canvas", "x": 0.519, "y": 0.417, "radius": 0.07},
            {"id": "c7_d4", "description": "Sunflower blossom head in window sill vase", "x": 0.163, "y": 0.358, "radius": 0.07}
        ]
    },
    {
        "id": "challenge_08",
        "title": "Morning Bakery Cafe",
        "themeTag": "Gourmet Patisserie",
        "difficulty": "hard",
        "description": "Detect pastry and cafe details outside this artisan bakery.",
        "imageAssetA": "assets/images/spot_difference/challenge_08_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_08_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c8_d1", "description": "Ripe strawberry garnish atop the central display cake", "x": 0.500, "y": 0.458, "radius": 0.06},
            {"id": "c8_d2", "description": "Steam curls rising from fresh espresso mug", "x": 0.744, "y": 0.567, "radius": 0.06},
            {"id": "c8_d3", "description": "Striped fabric awning segment color pattern", "x": 0.281, "y": 0.150, "radius": 0.08},
            {"id": "c8_d4", "description": "Potted lavender blossoms on the cobblestone walkway", "x": 0.125, "y": 0.783, "radius": 0.07}
        ]
    },
    {
        "id": "challenge_09",
        "title": "Ancient Library Nook",
        "themeTag": "Scholarly Archive",
        "difficulty": "hard",
        "description": "Investigate leather-bound volumes and brass artifacts.",
        "imageAssetA": "assets/images/spot_difference/challenge_09_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_09_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c9_d1", "description": "Green glass glowing banker lamp shade", "x": 0.675, "y": 0.583, "radius": 0.07},
            {"id": "c9_d2", "description": "Crimson silk bookmark trailing from top shelf book", "x": 0.319, "y": 0.217, "radius": 0.06},
            {"id": "c9_d3", "description": "Desk globe sphere mounted inside brass meridian", "x": 0.819, "y": 0.617, "radius": 0.07},
            {"id": "c9_d4", "description": "Golden star medallion in gothic stained glass arch", "x": 0.125, "y": 0.300, "radius": 0.07}
        ]
    },
    {
        "id": "challenge_10",
        "title": "Futuristic Science Lab",
        "themeTag": "Advanced Research",
        "difficulty": "hard",
        "description": "Spot subtle biochemical equipment discrepancies.",
        "imageAssetA": "assets/images/spot_difference/challenge_10_a.png",
        "imageAssetB": "assets/images/spot_difference/challenge_10_b.png",
        "imageWidth": 800,
        "imageHeight": 600,
        "differences": [
            {"id": "c10_d1", "description": "Cyan luminescent reagent inside distillation flask", "x": 0.381, "y": 0.617, "radius": 0.07},
            {"id": "c10_d2", "description": "Active green sine waveform on digital monitor", "x": 0.719, "y": 0.367, "radius": 0.06},
            {"id": "c10_d3", "description": "Fluorescent specimen glow on the microscope stage", "x": 0.219, "y": 0.683, "radius": 0.07},
            {"id": "c10_d4", "description": "Bound atom sphere on ceiling molecular model", "x": 0.519, "y": 0.183, "radius": 0.07}
        ]
    }
]

def main():
    generators = [
        draw_scene_1, draw_scene_2, draw_scene_3, draw_scene_4, draw_scene_5,
        draw_scene_6, draw_scene_7, draw_scene_8, draw_scene_9, draw_scene_10
    ]

    for idx, gen in enumerate(generators, start=1):
        filename_a = f"challenge_{idx:02d}_a.png"
        filename_b = f"challenge_{idx:02d}_b.png"
        path_a = os.path.join(OUTPUT_DIR, filename_a)
        path_b = os.path.join(OUTPUT_DIR, filename_b)

        img_a = gen(is_b=False)
        img_b = gen(is_b=True)

        img_a.save(path_a, "PNG")
        img_b.save(path_b, "PNG")
        print(f"Generated {filename_a} and {filename_b}")

    json_path = os.path.join(OUTPUT_DIR, "challenges_metadata.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(METADATA, f, indent=2)

    print(f"Metadata saved to {json_path}")
    print(f"Successfully generated all {len(generators) * 2} assets!")

if __name__ == "__main__":
    main()
