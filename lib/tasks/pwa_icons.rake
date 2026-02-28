namespace :pwa do
  desc "Generate placeholder PWA icons using ruby-vips (already in Gemfile). Run once, then replace with real branded icons."
  task generate_icons: :environment do
    require "vips"

    output_dir = Rails.root.join("public", "icons")
    FileUtils.mkdir_p(output_dir)

    # Brand colors: blue-500 (#3b82f6) → purple-500 (#a855f7), matching the CQ logo gradient
    blue   = [59,  130, 246, 255]
    purple = [168,  85, 247, 255]

    [
      { size: 192, dest: output_dir.join("icon-192.png") },
      { size: 512, dest: output_dir.join("icon-512.png") },
      { size: 180, dest: Rails.root.join("public", "apple-touch-icon.png") }
    ].each do |icon|
      size = icon[:size]

      # Build a vertical gradient from blue to purple by creating pixel rows
      pixels = Array.new(size) do |row|
        t = row.to_f / (size - 1)
        r = (blue[0] + (purple[0] - blue[0]) * t).round
        g = (blue[1] + (purple[1] - blue[1]) * t).round
        b = (blue[2] + (purple[2] - blue[2]) * t).round
        [r, g, b, 255] * size
      end.flatten.pack("C*")

      img = Vips::Image.new_from_memory(pixels, size, size, 4, :uchar)

      # Rounded corners via alpha mask
      radius = (size * 0.2).round
      mask_pixels = Array.new(size) do |y|
        Array.new(size) do |x|
          cx, cy = size / 2.0, size / 2.0
          in_corner = false

          [[radius, radius], [size - radius, radius], [radius, size - radius], [size - radius, size - radius]].each do |qx, qy|
            dx = x - qx + radius
            dy = y - qy + radius
            # Each quadrant: check if pixel is outside the rounded corner
            in_own_quadrant = (x < radius && y < radius) ||
                              (x >= size - radius && y < radius) ||
                              (x < radius && y >= size - radius) ||
                              (x >= size - radius && y >= size - radius)

            if in_own_quadrant
              closest_x = x < radius ? radius : size - radius
              closest_y = y < radius ? radius : size - radius
              dist = Math.sqrt((x - closest_x)**2 + (y - closest_y)**2)
              in_corner = dist > radius
            end
          end

          in_corner ? 0 : 255
        end
      end.flatten.pack("C*")

      mask = Vips::Image.new_from_memory(mask_pixels, size, size, 1, :uchar)

      # Flatten RGBA image to RGB, then re-attach alpha from mask
      rgb = img.extract_band(0, n: 3)
      final = rgb.bandjoin(mask)

      final.write_to_file(icon[:dest].to_s)
      puts "  Generated #{icon[:dest]}"
    end

    puts "\nDone! Icon files created in public/icons/ and public/apple-touch-icon.png"
    puts "Replace these with real branded icons when you have them."
  end
end
