import numpy as np
import cv2
import os
from skimage import io, color, morphology, filters, measure, transform
from scipy.ndimage import binary_fill_holes
import matplotlib.pyplot as plt


def process_single_image_set(i, file_name, file_dir, channels, marker_names, min_size):
    def read_image(channel_suffix):
        # file_name already includes the base name
        path = os.path.join(file_dir, f"{file_name}_{channel_suffix}.tif")
        print(f"Reading: {path}")  # Optional debug
        if not os.path.exists(path):
            print(f"Warning: Image file not found: {path}")
            return np.zeros((1, 1))  # or some default/fallback image

        return io.imread(path)


    blue = read_image(channels['dapi'])
    red = read_image(channels['red'])
    green = read_image(channels['green'])
    cyan = read_image(channels['cyan']) if 'cyan' in channels else None

    blue_gray = color.rgb2gray(blue) if blue.ndim == 3 else blue
    blue_bw = morphology.remove_small_objects(
        binary_fill_holes(morphology.closing(
            filters.threshold_otsu(blue_gray) < blue_gray,
            morphology.disk(25))), min_size)

    props = measure.regionprops(blue_bw.astype(int))
    if not props:
        print(f"[SKIPPED] No regions found in DAPI (blue) channel for image set {file_name}.")
        return (
            np.zeros(10000),  # blue
            np.zeros(10000),  # red
            np.zeros(10000),  # green
            np.zeros(10000)   # cyan
        )
    largest = max(props, key=lambda x: x.area)

    orientation = largest.orientation * 180 / np.pi  # convert to degrees

    def rotate(im): return transform.rotate(im, -orientation, resize=True, preserve_range=True).astype(im.dtype)

    blue, red, green = map(rotate, (blue, red, green))
    if cyan is not None:
        cyan = rotate(cyan)

    green_gray = color.rgb2gray(green) if green.ndim == 3 else green
    nonzero = green_gray[green_gray > 0]
    threshold = 4 * np.mean(nonzero) / 255
    green_bw = morphology.remove_small_objects(
        binary_fill_holes(morphology.closing(
            green_gray > threshold,
            morphology.disk(25))), min_size)

    props = measure.regionprops(measure.label(green_bw))
    largest_green = max(props, key=lambda x: x.area)
    rel_pos = largest_green.centroid[1] / green.shape[1]

    if rel_pos > 0.5:
        blue = np.fliplr(blue)
        red = np.fliplr(red)
        green = np.fliplr(green)
        if cyan is not None:
            cyan = np.fliplr(cyan)

    fig, axes = plt.subplots(3, 2 if cyan is not None else 1, figsize=(10, 10))
    axes[0, 0].imshow(blue, cmap='gray')
    axes[0, 0].set_title('DAPI')
    axes[1, 0].imshow(green, cmap='gray')
    axes[1, 0].set_title(marker_names['green'])
    axes[2, 0].imshow(red, cmap='gray')
    axes[2, 0].set_title(marker_names['red'])
    if cyan is not None:
        axes[0, 1].imshow(cyan, cmap='gray')
        axes[0, 1].set_title(marker_names['cyan'])
    plt.tight_layout()
    plt.close(fig)

    def quantify(channel_gs):
        logical = channel_gs > 0
        rois = measure.label(logical)
        props = measure.regionprops(rois)
        largest_roi = max(props, key=lambda p: p.bbox_area)
        sl = largest_roi.slice
        roi = channel_gs[sl]
        col_sum = roi.sum(axis=0)
        x_scale = np.linspace(0, 1, len(col_sum))
        x_interp = np.linspace(0, 1, 10000)
        return np.interp(x_interp, x_scale, col_sum)

    blue_interp = quantify(color.rgb2gray(blue) if blue.ndim == 3 else blue)
    red_interp = quantify(color.rgb2gray(red) if red.ndim == 3 else red)
    green_interp = quantify(color.rgb2gray(green) if green.ndim == 3 else green)
    cyan_interp = quantify(color.rgb2gray(cyan) if (cyan is not None and cyan.ndim == 3) else cyan) if cyan is not None else np.zeros(10000)

    return blue_interp, red_interp, green_interp, cyan_interp


def process_all_image_sets(num_sets, file_name_scheme, file_dir, channels, marker_names, min_size):
    # Predefine results table
    results_table = [["Image Set", "DAPI", marker_names["red"], marker_names["green"], marker_names["cyan"]]]
    for _ in range(num_sets + 1):
        results_table.append([None] * 5)
    results_table.append(["Average Results", None, None, None, None])

    # Predefine interpolated intensity arrays
    blue_interpolate = np.zeros((num_sets, 10000))
    red_interpolate = np.zeros((num_sets, 10000))
    green_interpolate = np.zeros((num_sets, 10000))
    cyan_interpolate = np.zeros((num_sets, 10000))

    # Process each image set
    for i in range(num_sets):
        print(f"Processing data set {i + 1}")
        image_name = f"{file_name_scheme}_{i + 1}"
        results_table[i + 1][0] = image_name

        blue_interp, red_interp, green_interp, cyan_interp = process_single_image_set(
            i=i,
            file_name=image_name,
            file_dir=file_dir,
            channels=channels,
            marker_names=marker_names,
            min_size=min_size
        )

        blue_interpolate[i, :] = blue_interp
        red_interpolate[i, :] = red_interp
        green_interpolate[i, :] = green_interp
        cyan_interpolate[i, :] = cyan_interp

    return results_table, blue_interpolate, red_interpolate, green_interpolate, cyan_interpolate
