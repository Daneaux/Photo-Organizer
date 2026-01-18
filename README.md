# Photo Organizer

A macOS app that organizes photos and videos into a clean, date-based folder structure.

## Features

- **Smart Date Detection**: Extracts dates from EXIF metadata, video metadata, or directory names
- **Folder Selection**: Choose which folders to process with a tree view interface
- **Event Descriptions**: Automatically suggests event names from folder names (e.g., "Beach Vacation")
- **Preview Before Moving**: See exactly where files will go before committing
- **Undo Support**: Generates shell scripts to reverse the operation if needed
- **Duplicate Handling**: Automatically renames files to avoid conflicts

## Output Structure

Files are organized into:
```
Destination/
├── 2024/
│   ├── 01-15/
│   ├── 03-22 Birthday Party/
│   └── 07-04 Beach Vacation/
├── 2023/
│   └── ...
```

## Workflow

1. **Select Folders**: Choose source and destination directories
2. **Browse & Select**: View folder tree, select which folders to process
3. **Scan**: App extracts metadata from photos/videos
4. **Confirm Dates**: For files without metadata, confirm or enter dates manually
5. **Event Names**: Review suggested event descriptions for folders
6. **Preview**: See all planned file moves
7. **Execute**: Move files with progress tracking

## Supported File Types

**Images**: JPG, JPEG, PNG, HEIC, GIF, BMP, TIFF, RAW formats (CR2, CR3, CRW, RW2, RAF)

**Videos**: MP4, MOV, AVI, MKV, M4V

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ to build

## Building

1. Open `Photo Organizer.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (⌘R)

## Privacy

The app runs entirely locally. No data is sent to external servers. Files are moved (not copied) to preserve disk space.
