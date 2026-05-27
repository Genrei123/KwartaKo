import os
import sys

def main():
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not installed. Installing Pillow...")
        import subprocess
        subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
        from PIL import Image

    input_path = r"c:\GitHub\Vibes\kwartako\assets\icon\splash_icon.png"
    output_path = r"c:\GitHub\Vibes\kwartako\assets\icon\splash_icon_padded.png"

    if not os.path.exists(input_path):
        print(f"Error: Input file {input_path} does not exist.")
        return

    print("Opening splash icon...")
    img = Image.open(input_path)
    
    # 1. We want the logo to be centered on a 1152x1152 canvas (Android 12 standard)
    canvas_size = 1152
    
    # 2. To avoid the zoomed-in / cut-off look, the logo should occupy about 40% of the canvas size
    # 40% of 1152 is ~460px
    target_logo_dim = 460
    
    # Scale original image maintaining aspect ratio
    img.thumbnail((target_logo_dim, target_logo_dim), Image.Resampling.LANCZOS)
    
    # Create transparent canvas
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (255, 255, 255, 0))
    
    # Center the logo on canvas
    x = (canvas_size - img.width) // 2
    y = (canvas_size - img.height) // 2
    
    canvas.paste(img, (x, y), img if img.mode == 'RGBA' else None)
    
    # Save the result
    canvas.save(output_path, "PNG")
    print(f"Successfully padded splash icon and saved to: {output_path}")

if __name__ == "__main__":
    main()
