#!/usr/bin/env python3
"""
Pulsar macOS App Icon & Brand Logo Generator
Generates:
1. High-resolution master 1024x1024 app icon PNG
2. macOS standard squircle with glassmorphic data capsule & spinning neutron star (pulsar) core
3. Complete .iconset and builds AppIcon.icns using iconutil
4. Web assets (logo.png, favicon.png)
"""

import os
import math
import subprocess
from PIL import Image, ImageDraw, ImageFilter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.dirname(SCRIPT_DIR)
BUILD_DIR = os.path.join(ROOT_DIR, "build")
ASSETS_DIR = os.path.join(ROOT_DIR, "assets")
WEB_ASSETS_DIR = os.path.join(ROOT_DIR, "Website", "assets")

def create_pulsar_master_icon(size=1024):
    # Create RGBA canvas
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. macOS Squircle Geometry (Centered 824x824 at 1024 canvas)
    # macOS standard icon size is ~824x824 within 1024x1024 bounding box with shadow
    margin = 100
    sq_size = size - (margin * 2)
    radius = int(sq_size * 0.224) # Apple continuous squircle approx radius

    # Drop Shadow layer
    shadow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_img)
    s_box = [margin, margin + 14, margin + sq_size, margin + sq_size + 14]
    s_draw.rounded_rectangle(s_box, radius=radius, fill=(0, 0, 0, 140))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(24))
    img.paste(shadow_img, (0, 0), shadow_img)

    # Base Squircle Mask
    mask = Image.new("L", (size, size), 0)
    m_draw = ImageDraw.Draw(mask)
    sq_box = [margin, margin, margin + sq_size, margin + sq_size]
    m_draw.rounded_rectangle(sq_box, radius=radius, fill=255)

    # Base Background Gradient (Deep Space Navy to Cosmic Violet)
    base_bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(base_bg)
    
    # Linear gradient across diagonal
    for y in range(margin, margin + sq_size):
        for x in range(margin, margin + sq_size):
            t = ((x - margin) + (y - margin)) / (sq_size * 2)
            # From #0B0F19 (11, 15, 25) to #1E1035 (30, 16, 53)
            r = int(11 + (32 - 11) * t)
            g = int(15 + (18 - 15) * t)
            b = int(28 + (58 - 28) * t)
            b_draw.point((x, y), fill=(r, g, b, 255))

    # Add Nebula Radial Glow in background (center offset towards top-left)
    cx, cy = size // 2, size // 2
    nebula = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    n_draw = ImageDraw.Draw(nebula)
    for r in range(360, 0, -6):
        alpha = int(35 * (1 - r / 360.0))
        n_draw.ellipse([cx - r - 40, cy - r - 40, cx + r - 40, cy + r - 40], fill=(79, 70, 229, alpha))
    for r in range(240, 0, -4):
        alpha = int(45 * (1 - r / 240.0))
        n_draw.ellipse([cx - r + 30, cy - r + 30, cx + r + 30, cy + r + 30], fill=(13, 148, 136, alpha))
    nebula = nebula.filter(ImageFilter.GaussianBlur(30))
    base_bg.paste(nebula, (0, 0), nebula)

    # 2. Geometric Archive Capsule / Data Crystal Cube (Translucent 3D facets)
    capsule = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    c_draw = ImageDraw.Draw(capsule)

    # Hexagonal / Isometric crystal facet points centered at (cx, cy)
    hex_radius = 230
    points = []
    for i in range(6):
        angle_deg = 30 + i * 60
        rad = math.radians(angle_deg)
        px = cx + hex_radius * math.cos(rad)
        py = cy + hex_radius * math.sin(rad)
        points.append((px, py))

    # Top, Bottom-Left, Bottom-Right facets
    p_center = (cx, cy)
    # Top facet: points[5], points[0], points[1], p_center
    c_draw.polygon([points[4], points[5], points[0], p_center], fill=(255, 255, 255, 18))
    # Bottom Right facet
    c_draw.polygon([points[0], points[1], points[2], p_center], fill=(0, 242, 254, 25))
    # Bottom Left facet
    c_draw.polygon([points[2], points[3], points[4], p_center], fill=(157, 78, 221, 28))

    # Capsule Outer Rim (Neon glowing boundary)
    c_draw.polygon(points, outline=(0, 242, 254, 180), width=3)
    # Inner facet lines
    c_draw.line([p_center, points[0]], fill=(0, 242, 254, 140), width=2)
    c_draw.line([p_center, points[2]], fill=(157, 78, 221, 140), width=2)
    c_draw.line([p_center, points[4]], fill=(255, 255, 255, 140), width=2)

    # Data Archive Grid / Nodes on capsule borders
    for pt in points:
        c_draw.ellipse([pt[0] - 5, pt[1] - 5, pt[0] + 5, pt[1] + 5], fill=(0, 242, 254, 230), outline=(255, 255, 255, 255), width=2)

    base_bg.paste(capsule, (0, 0), capsule)

    # 3. Relativistic Particle Jets (Diagonal Pulsar Energy Beams)
    jets = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    j_draw = ImageDraw.Draw(jets)

    jet_angle = math.radians(-35) # diagonal slant
    cos_j = math.cos(jet_angle)
    sin_j = math.sin(jet_angle)

    # Top-right beam & Bottom-left beam
    for dist in range(1, 380, 2):
        progress = dist / 380.0
        alpha = int(220 * (1.0 - progress))
        beam_w = int(12 * (1.0 - progress * 0.4))
        
        # Color transition from White to Cyan to Electric Violet
        if progress < 0.3:
            col = (255, 255, 255, alpha)
        elif progress < 0.7:
            col = (0, 242, 254, alpha)
        else:
            col = (168, 85, 247, alpha)

        p1_x = cx + dist * cos_j
        p1_y = cy + dist * sin_j
        p2_x = cx - dist * cos_j
        p2_y = cy - dist * sin_j

        j_draw.ellipse([p1_x - beam_w, p1_y - beam_w, p1_x + beam_w, p1_y + beam_w], fill=col)
        j_draw.ellipse([p2_x - beam_w, p2_y - beam_w, p2_x + beam_w, p2_y + beam_w], fill=col)

    jets = jets.filter(ImageFilter.GaussianBlur(4))
    base_bg.paste(jets, (0, 0), jets)

    # 4. Concentric Pulsar Accretion Rings (Swirling Cosmic Rings)
    rings = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    r_draw = ImageDraw.Draw(rings)

    # Ring 1 (Outer Purple Ring, tilted ellipse)
    r1_w, r1_h = 320, 140
    r_draw.ellipse([cx - r1_w//2, cy - r1_h//2, cx + r1_w//2, cy + r1_h//2], outline=(168, 85, 247, 160), width=4)
    # Ring 2 (Inner Cyan Ring, steeper angle)
    r2_w, r2_h = 240, 100
    r_draw.ellipse([cx - r2_w//2, cy - r2_h//2, cx + r2_w//2, cy + r2_h//2], outline=(0, 242, 254, 210), width=5)
    # Ring 3 (Tight Core Ring)
    r3_w, r3_h = 160, 70
    r_draw.ellipse([cx - r3_w//2, cy - r3_h//2, cx + r3_w//2, cy + r3_h//2], outline=(255, 255, 255, 230), width=3)

    # Rotate rings slightly
    rings_rotated = rings.rotate(22, resample=Image.BICUBIC, center=(cx, cy))
    base_bg.paste(rings_rotated, (0, 0), rings_rotated)

    # 5. Glowing Pulsar Core (Blinding Light & Multi-Layer Bloom)
    core = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    k_draw = ImageDraw.Draw(core)

    # Outer Bloom (Violet / Blue)
    for rad in range(120, 0, -3):
        a = int(60 * (1 - rad / 120.0))
        k_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(147, 51, 234, a))

    # Mid Bloom (Cyan)
    for rad in range(70, 0, -2):
        a = int(140 * (1 - rad / 70.0))
        k_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(0, 242, 254, a))

    # Bright White Core
    for rad in range(32, 0, -1):
        a = int(255 * (1 - (rad / 32.0)**1.5))
        k_draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 255, 255, a))

    core = core.filter(ImageFilter.GaussianBlur(3))
    base_bg.paste(core, (0, 0), core)

    # 6. Ultra-bright 4-point Star Flare
    flare = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    f_draw = ImageDraw.Draw(flare)
    flare_len = 110
    f_draw.line([cx - flare_len, cy, cx + flare_len, cy], fill=(255, 255, 255, 230), width=3)
    f_draw.line([cx, cy - flare_len, cx, cy + flare_len], fill=(255, 255, 255, 230), width=3)
    # diagonal micro flare
    m_len = 50
    f_draw.line([cx - m_len, cy - m_len, cx + m_len, cy + m_len], fill=(0, 242, 254, 180), width=2)
    f_draw.line([cx - m_len, cy + m_len, cx + m_len, cy - m_len], fill=(0, 242, 254, 180), width=2)
    flare = flare.filter(ImageFilter.GaussianBlur(1))
    base_bg.paste(flare, (0, 0), flare)

    # 7. Subtle Top Specular Glass Curve Highlight
    specular = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sp_draw = ImageDraw.Draw(specular)
    sp_box = [margin + 8, margin + 4, margin + sq_size - 8, margin + int(sq_size * 0.48)]
    sp_draw.chord(sp_box, start=180, end=0, fill=(255, 255, 255, 28))
    specular = specular.filter(ImageFilter.GaussianBlur(12))
    base_bg.paste(specular, (0, 0), specular)

    # 8. Squircle Border / Inner Bevel (Apple HIG style rim highlight)
    border = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(border)
    b_draw.rounded_rectangle(sq_box, radius=radius, outline=(255, 255, 255, 60), width=2)
    base_bg.paste(border, (0, 0), border)

    # Apply the Squircle Mask to base_bg
    final_icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    final_icon.paste(base_bg, (0, 0), mask)

    # Combine with drop shadow
    img.paste(final_icon, (0, 0), final_icon)

    return img

def main():
    print("🌌 [PULSAR LOGO] Master 1024x1024 İkon Üretiliyor...")
    os.makedirs(BUILD_DIR, exist_ok=True)
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(WEB_ASSETS_DIR, exist_ok=True)

    icon = create_pulsar_master_icon(1024)

    # Save Master PNG
    master_png = os.path.join(ASSETS_DIR, "logo.png")
    icon.save(master_png, "PNG")
    print(f"✅ Master Logo kaydedildi: {master_png}")

    # Copy to Website assets
    web_logo = os.path.join(WEB_ASSETS_DIR, "logo.png")
    icon.save(web_logo, "PNG")
    
    # Save Favicons
    favicon_64 = icon.resize((64, 64), Image.LANCZOS)
    favicon_64.save(os.path.join(ROOT_DIR, "Website", "favicon.png"), "PNG")
    favicon_32 = icon.resize((32, 32), Image.LANCZOS)
    favicon_32.save(os.path.join(ROOT_DIR, "Website", "favicon.ico"))
    print("✅ Web sitesi favicon ve logoları üretildi.")

    # Generate macOS .iconset
    iconset_dir = os.path.join(BUILD_DIR, "AppIcon.iconset")
    if os.path.exists(iconset_dir):
        import shutil
        shutil.rmtree(iconset_dir)
    os.makedirs(iconset_dir, exist_ok=True)

    icon_specs = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    print("⚙️ macOS Retina çözünürlükleri hazırlanıyor...")
    for filename, sz in icon_specs:
        resized = icon.resize((sz, sz), Image.LANCZOS)
        resized.save(os.path.join(iconset_dir, filename), "PNG")

    # Run iconutil to produce AppIcon.icns
    icns_path = os.path.join(BUILD_DIR, "AppIcon.icns")
    print(f"📦 [iconutil] {icns_path} derleniyor...")
    res = subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], capture_output=True, text=True)
    if res.returncode == 0:
        print(f"🎉 AppIcon.icns başarıyla oluşturuldu: {icns_path}")
    else:
        print(f"⚠️ iconutil uyarısı/hatası: {res.stderr}")

    # Also save to PulsarApp Resources directory
    res_dir = os.path.join(ROOT_DIR, "PulsarApp", "Sources", "Pulsar", "Resources")
    os.makedirs(res_dir, exist_ok=True)
    import shutil
    shutil.copy(icns_path, os.path.join(res_dir, "AppIcon.icns"))
    shutil.copy(master_png, os.path.join(res_dir, "logo.png"))
    print(f"✅ AppIcon.icns ve logo.png -> {res_dir} dizinine kopyalandı.")

if __name__ == "__main__":
    main()
