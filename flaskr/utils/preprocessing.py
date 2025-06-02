import os
from pathlib import Path

def preprocess_directory(directory_path: str, num_channels: int, min_file_size: int = 5000):
    """
    Preprocess image directory: filter valid image files and count sets.
    
    Args:
        directory_path (str): Path to the directory of images.
        num_channels (int): Number of channels per image set (3 or 4).
        min_file_size (int): Minimum file size to consider valid (default 5000 bytes).
        
    Returns:
        num_image_sets (int): Number of image sets found.
        image_files (list): List of valid image file names (sorted).
    """
    # Make sure directory exists
    if not os.path.isdir(Path(directory_path)):
        raise FileNotFoundError(f"Directory '{directory_path}' does not exist.")

    # Get all files in directory with file size > 5000 bytes
    valid_files = [
        f for f in os.listdir(directory_path)
        if os.path.isfile(os.path.join(directory_path, f)) and os.path.getsize(os.path.join(directory_path, f)) > min_file_size
    ]

    # Sort file list for consistent ordering
    valid_files.sort()

    # Compute number of image sets
    num_images = len(valid_files)
    if num_channels == 4:
        num_sets = num_images // 4
    elif num_channels == 3:
        num_sets = num_images // 3
        print("Running data analysis for a 3-channel image set.")
    else:
        raise ValueError("Number of channels must be 3 or 4.")

    print(f"Found {num_sets} image sets in: {directory_path}")
    return num_sets, valid_files
