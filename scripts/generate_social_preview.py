import math
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def generate_social_preview(output_path="docs/social_preview.png"):
    W, H = 1280, 640
    img = Image.new("RGBA", (W, H), (8, 12, 20, 255))

    # 1. Mesh Ambient Glows
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)

    def draw_radial_glow(draw, cx, cy, radius, r, g, b, max_alpha):
        for i in range(radius, 0, -4):
            alpha = int(max_alpha * (1 - (i / radius)**1.4))
            draw.ellipse([cx - i, cy - i, cx + i, cy + i], fill=(r, g, b, alpha))

    # Large ambient backlights
    draw_radial_glow(glow_draw, 980, 290, 420, 0, 229, 255, 36)   # Cyan glow under player
    draw_radial_glow(glow_draw, 240, 140, 320, 99, 102, 241, 35)  # Indigo behind title
    draw_radial_glow(glow_draw, 720, 480, 360, 99, 102, 241, 28)  # Indigo bottom-center
    draw_radial_glow(glow_draw, 100, 520, 280, 0, 229, 255, 20)   # Cyan bottom-left

    img = Image.alpha_composite(img, glow)

    # 2. Modern subtle dot grid
    grid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    grid_draw = ImageDraw.Draw(grid)
    for x in range(32, W - 32, 28):
        for y in range(32, H - 32, 28):
            grid_draw.rectangle([x, y, x + 1, y + 1], fill=(255, 255, 255, 10))

    img = Image.alpha_composite(img, grid)

    # Fonts
    font_repo = ImageFont.truetype('/System/Library/Fonts/Avenir Next.ttc', 15, index=2)     # Demi Bold
    font_title = ImageFont.truetype('/System/Library/Fonts/Avenir Next.ttc', 48, index=8)    # Heavy
    font_sub = ImageFont.truetype('/System/Library/Fonts/Avenir Next.ttc', 21, index=0)      # Bold
    font_desc = ImageFont.truetype('/System/Library/Fonts/Avenir Next.ttc', 15, index=7)     # Regular
    font_pill = ImageFont.truetype('/System/Library/Fonts/Avenir Next.ttc', 13, index=2)     # Demi Bold
    font_footer = ImageFont.truetype('/System/Library/Fonts/Avenir Next.ttc', 13, index=7)   # Regular

    draw = ImageDraw.Draw(img)

    # --- LEFT COLUMN (x=68 safe zone) ---
    left_x = 68

    # 1. GitHub Repo Pill
    pill_y = 65
    repo_text = "github.com / arnovo / iptvplay"
    bbox = font_repo.getbbox(repo_text)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    pw, ph = tw + 46, 32

    draw.rounded_rectangle([left_x, pill_y, left_x + pw, pill_y + ph], radius=16, fill=(19, 27, 46, 230), outline=(43, 58, 90, 255), width=1)
    # Green pulse dot
    draw.ellipse([left_x + 14, pill_y + 11, left_x + 22, pill_y + 19], fill=(16, 185, 129, 255))
    draw.text((left_x + 30, pill_y + 6), repo_text, fill=(148, 163, 184, 255), font=font_repo)

    # 2. App Icon & Brand Title
    brand_y = 125
    icon_size = 76
    app_icon_path = "assets/icon/app_icon.png"
    if os.path.exists(app_icon_path):
        icon_src = Image.open(app_icon_path).convert("RGBA")
        icon_src = icon_src.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        
        # Rounded mask
        mask = Image.new("L", (icon_size, icon_size), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, icon_size, icon_size], radius=18, fill=255)
        
        # Icon glow
        ig = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(ig).rounded_rectangle([left_x - 4, brand_y - 4, left_x + icon_size + 4, brand_y + icon_size + 4], radius=22, fill=(0, 229, 255, 65))
        ig = ig.filter(ImageFilter.GaussianBlur(8))
        img = Image.alpha_composite(img, ig)
        
        img.paste(icon_src, (left_x, brand_y), mask)
        draw = ImageDraw.Draw(img)
        draw.rounded_rectangle([left_x, brand_y, left_x + icon_size, brand_y + icon_size], radius=18, outline=(0, 229, 255, 190), width=2)

    text_x = left_x + icon_size + 20
    draw.text((text_x, brand_y - 2), "IPTV Play", fill=(248, 250, 252, 255), font=font_title)
    draw.text((text_x, brand_y + 50), "Smart IPTV & Video Engine", fill=(0, 229, 255, 255), font=font_sub)

    # 3. Description
    desc_y = 232
    desc_lines = [
        "High-performance cross-platform smart player",
        "engineered with Flutter & MediaKit (libmpv).",
        "Dual protocol support for Xtream Codes and M3U,",
        "with a native 10-foot UI designed for Smart TVs."
    ]
    cy = desc_y
    for dl in desc_lines:
        draw.text((left_x, cy), dl, fill=(148, 163, 184, 255), font=font_desc)
        cy += 23

    # 4. Feature Badges with clean styled color dots
    badge_y = 360
    badges = [
        ("MediaKit (libmpv)", (0, 229, 255)),
        ("Xtream & M3U8", (99, 102, 241)),
        ("Smart TV D-Pad", (16, 185, 129)),
        ("Live PVR Recording", (245, 158, 11)),
        ("LAN Stream Server", (0, 229, 255)),
        ("macOS • Android TV", (148, 163, 184)),
    ]

    bx = left_x
    by = badge_y
    for label, color in badges:
        b_box = font_pill.getbbox(label)
        bw = b_box[2] - b_box[0] + 32
        bh = 28
        if bx + bw > 575:
            bx = left_x
            by += bh + 9
        
        # Pill background
        draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=14, fill=(19, 27, 46, 210), outline=(color[0], color[1], color[2], 130), width=1)
        # Indicator dot
        draw.ellipse([bx + 10, by + 10, bx + 18, by + 18], fill=(color[0], color[1], color[2], 255))
        # Text
        draw.text((bx + 24, by + 5), label, fill=(248, 250, 252, 240), font=font_pill)
        bx += bw + 9

    # 5. Footer Specs
    draw.text((left_x, 560), "Flutter 3.47+  •  Dart 3.13+  •  24 Automated Tests  •  Zero Telemetry", fill=(100, 116, 139, 255), font=font_footer)

    # --- RIGHT COLUMN: LAYERED WINDOW MOCKUPS ---
    # Background window: Welcome screen (partially visible, layered behind)
    bg_shot_path = "docs/screenshots/welcome_screen.png"
    if os.path.exists(bg_shot_path):
        bg_shot = Image.open(bg_shot_path).convert("RGBA")
        bg_w, bg_h = 560, 338
        bg_resized = bg_shot.resize((bg_w, bg_h), Image.Resampling.LANCZOS)
        
        bg_x, bg_y = 660, 85
        
        # Shadow for bg window
        bg_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(bg_shadow).rounded_rectangle([bg_x, bg_y + 10, bg_x + bg_w, bg_y + bg_h + 15], radius=20, fill=(0, 0, 0, 150))
        bg_shadow = bg_shadow.filter(ImageFilter.GaussianBlur(25))
        img = Image.alpha_composite(img, bg_shadow)
        
        # Dimmer overlay
        dimmer = Image.new("RGBA", (bg_w, bg_h), (0, 0, 0, 60))
        bg_resized = Image.alpha_composite(bg_resized, dimmer)
        
        # Rounded mask
        bg_mask = Image.new("L", (bg_w, bg_h), 0)
        ImageDraw.Draw(bg_mask).rounded_rectangle([0, 0, bg_w, bg_h], radius=14, fill=255)
        img.paste(bg_resized, (bg_x, bg_y), bg_mask)
        
        draw = ImageDraw.Draw(img)
        draw.rounded_rectangle([bg_x, bg_y, bg_x + bg_w, bg_y + bg_h], radius=14, outline=(43, 58, 90, 200), width=1)

    # Foreground window: Live Player (prominent and crisp!)
    fg_shot_path = "docs/screenshots/live_player.png"
    if os.path.exists(fg_shot_path):
        fg_shot = Image.open(fg_shot_path).convert("RGBA")
        
        fg_w, fg_h = 600, 362
        fg_resized = fg_shot.resize((fg_w, fg_h), Image.Resampling.LANCZOS)
        
        fg_x, fg_y = 600, 185
        
        # Deep drop shadow
        fg_shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(fg_shadow).rounded_rectangle([fg_x - 10, fg_y + 15, fg_x + fg_w + 10, fg_y + fg_h + 30], radius=22, fill=(0, 0, 0, 230))
        fg_shadow = fg_shadow.filter(ImageFilter.GaussianBlur(32))
        img = Image.alpha_composite(img, fg_shadow)
        
        # Cyan neon perimeter glow
        fg_glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(fg_glow).rounded_rectangle([fg_x - 2, fg_y - 2, fg_x + fg_w + 2, fg_y + fg_h + 2], radius=16, fill=(0, 229, 255, 75))
        fg_glow = fg_glow.filter(ImageFilter.GaussianBlur(14))
        img = Image.alpha_composite(img, fg_glow)
        
        # Rounded mask for fg
        fg_mask = Image.new("L", (fg_w, fg_h), 0)
        ImageDraw.Draw(fg_mask).rounded_rectangle([0, 0, fg_w, fg_h], radius=14, fill=255)
        img.paste(fg_resized, (fg_x, fg_y), fg_mask)
        
        draw = ImageDraw.Draw(img)
        draw.rounded_rectangle([fg_x, fg_y, fg_x + fg_w, fg_y + fg_h], radius=14, outline=(0, 229, 255, 170), width=2)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, format="PNG", optimize=True)
    print(f"Social preview successfully generated at: {output_path}")

if __name__ == "__main__":
    generate_social_preview()
