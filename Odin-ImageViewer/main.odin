package main

import "core:fmt"
import rl "vendor:raylib"

load_dropped_images :: proc(texArr: ^[dynamic]rl.Texture2D) {
	files: rl.FilePathList
	if rl.IsFileDropped() {
		files = rl.LoadDroppedFiles()
		for i: u32 = 0; i < files.count; i += 1 {
			append_elem(texArr, rl.LoadTexture(files.paths[i]))
		}
	}
	rl.UnloadDroppedFiles(files)
}

unload_dropped_images :: proc(loadedTextures: ^[dynamic]rl.Texture2D) {
	fmt.printf("Unloading %d textures!\n", len(loadedTextures))

	for i := 0; i < len(loadedTextures); i += 1 {
		rl.UnloadTexture(loadedTextures[i])
	}

	clear(loadedTextures)
	free(loadedTextures)
}

draw_dropped_image :: proc(tex: ^rl.Texture2D, lowerBand: ^rl.Rectangle, zoom: f32) {
	if tex == nil {
		return
	}

	sw := rl.GetScreenWidth()
	sh := rl.GetScreenHeight()
	usable_h := int(sh) - int(lowerBand.height)

	target_aspect := f32(sw) / f32(usable_h)
	tex_aspect := f32(tex.width) / f32(tex.height)

	src := rl.Rectangle{0, 0, f32(tex.width), f32(tex.height)}

	dst_w: f32
	dst_h: f32

	if tex_aspect > target_aspect {
		dst_w = f32(sw) * zoom
		dst_h = (f32(sw) / tex_aspect) * zoom
	} else {
		// Fit height
		dst_h = f32(usable_h) * zoom
		dst_w = (f32(usable_h) * tex_aspect) * zoom
	}

	dst := rl.Rectangle {
		x      = (f32(sw) - dst_w) * 0.5,
		y      = (f32(usable_h) - dst_h) * 0.5,
		width  = dst_w,
		height = dst_h,
	}

	rl.DrawTexturePro(tex^, src, dst, rl.Vector2{0, 0}, 0.0, rl.WHITE)
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE})
	rl.InitWindow(800, 600, "ImageViewer")
	rl.SetExitKey(rl.KeyboardKey.KEY_NULL)

	droppedImages: [dynamic]rl.Texture2D
	currentImage := 0

	LOWER_BAND_HEIGHT :: 45
	NO_FILES_LOADED_MESSAGE :: "Drag and drop an image file (or multiple) to load..."
	NO_FILES_LOADED_MESSAGE_FSIZE :: 25

	for !rl.WindowShouldClose() {
		lowerband: rl.Rectangle = {
			height = LOWER_BAND_HEIGHT,
			width  = f32(rl.GetScreenWidth()),
			y      = f32(rl.GetScreenHeight()) - LOWER_BAND_HEIGHT,
			x      = 0,
		}
		droppedLen := len(droppedImages)

		if rl.IsKeyPressed(rl.KeyboardKey.ESCAPE) {
			unload_dropped_images(&droppedImages)
		}
		if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
			currentImage += 1
			if currentImage >= droppedLen {
				currentImage = droppedLen - 1
			}
		}
		if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
			currentImage -= 1
			if currentImage < 0 {
				currentImage = 0
			}
		}
		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			unload_dropped_images(&droppedImages)
			droppedLen = 0
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.DARKGRAY)

		if droppedLen > 0 {
			// start ui
			rl.DrawRectangleRec(lowerband, rl.BLACK)
			rl.DrawText(
				rl.TextFormat(
					"Image %d/%d - Space to unload files! | Arrow keys to page through!",
					currentImage + 1,
					droppedLen,
				),
				5,
				i32(lowerband.y) + 25 / 2,
				LOWER_BAND_HEIGHT - 25,
				rl.WHITE,
			)
			// end ui
		} else {
			textWidth := rl.MeasureText(NO_FILES_LOADED_MESSAGE, NO_FILES_LOADED_MESSAGE_FSIZE)

			// Compute centered position
			x := (rl.GetScreenWidth() - textWidth) / 2
			y := (rl.GetScreenHeight() - NO_FILES_LOADED_MESSAGE_FSIZE) / 2

			// Draw
			rl.DrawText(NO_FILES_LOADED_MESSAGE, x, y, NO_FILES_LOADED_MESSAGE_FSIZE, rl.WHITE)
		}

		load_dropped_images(&droppedImages)
		if droppedLen > 0 {
			draw_dropped_image(&droppedImages[currentImage], &lowerband, 1)
		}
		rl.EndDrawing()
	}
	unload_dropped_images(&droppedImages)
	rl.CloseWindow()
}
