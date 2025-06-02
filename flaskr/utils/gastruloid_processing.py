
import numpy as np
import cv2
import os
from skimage import io, color, morphology, filters, measure, transform
from scipy.ndimage import binary_fill_holes
import matplotlib.pyplot as plt

def process(file_dir, file_prefix, channels, min_size, n_sets):
    results = [['Image Set', 'DAPI', 'Red', 'Green', 'Cyan']]
    blue_interp = np.zeros((n_sets, 10000))
    red_interp = np.zeros((n_sets, 10000))
    green_interp = np.zeros((n_sets, 10000))
    cyan_interp = np.zeros((n_sets, 10000))

    for i in range(1, n_sets + 1):
        print(f"Processing data set {i}")
        name = f"{file_prefix}_{i}"
        results.append([name, None, None, None, None])  # placeholder

        # Load images
        suffix = lambda channel: f"{name}_{channel}.tif"
        load = lambda channel: io.imread(os.path.join(file_dir, suffix(channel)))

        blue = load(channels['dapi'])
        red = load(channels['red'])
        green = load(channels['green'])
        cyan = load(channels['cyan']) if 'cyan' in channels else None

        # Convert to grayscale
        blue_gray = color.rgb2gray(blue) if blue.ndim == 3 else blue
        blue_bw = blue_gray > filters.threshold_otsu(blue_gray)
        blue_bw = binary_fill_holes(blue_bw)
        blue_bw = morphology.closing(blue_bw, morphology.disk(25))
        blue_bw = morphology.remove_small_objects(blue_bw, min_size)

        # Get orientation
        props = measure.regionprops(blue_bw.astype(int))
        largest = max(props, key=lambda p: p.area)
        angle = largest.orientation

        # Rotate all
        rot = lambda img: transform.rotate(img, -angle, resize=True, preserve_range=True).astype(img.dtype)
        red, blue, green = map(rot, (red, blue, green))
        if cyan is not None:
            cyan = rot(cyan)

        # Flip if green object on right
        green_gray = color.rgb2gray(green) if green.ndim == 3 else green
        avg_int = green_gray[green_gray > 0].mean()
        green_bw = green_gray > (4 * avg_int / 255)
        green_bw = binary_fill_holes(green_bw)
        green_bw = morphology.closing(green_bw, morphology.disk(25))
        green_bw = morphology.remove_small_objects(green_bw, min_size)

        props = measure.regionprops(green_bw.astype(int))
        green_obj = max(props, key=lambda p: p.area)
        if green_obj.centroid[1] / green.shape[1] > 0.5:
            red = np.fliplr(red)
            blue = np.fliplr(blue)
            green = np.fliplr(green)
            if cyan is not None:
                cyan = np.fliplr(cyan)

        # Crop ROI from blue channel
        roi = largest.bbox
        top, left, bottom, right = roi
        xscale = np.linspace(0, 1, right - left)
        xinterp = np.linspace(0, 1, 10000)

        # Quantify intensity
        def quantify(img, idx):
            img_gray = color.rgb2gray(img) if img.ndim == 3 else img
            roi_img = img_gray[top:bottom, left:right]
            summed = roi_img.sum(axis=0)
            return np.interp(xinterp, xscale, summed)

        blue_interp[i - 1] = quantify(blue, i)
        red_interp[i - 1] = quantify(red, i)
        green_interp[i - 1] = quantify(green, i)
        if cyan is not None:
            cyan_interp[i - 1] = quantify(cyan, i)

        # Visualization (optional)
        plt.figure(i)
        for j, (img, title, colorname) in enumerate([(blue, 'DAPI', 'blue'), (green, 'Green', 'green'), (red, 'Red', 'red'), (cyan, 'Cyan', 'cyan') if cyan is not None else None]):
            if img is not None:
                plt.subplot(3, 2, j+1)
                plt.imshow(img, cmap='gray')
                plt.title(title, fontsize=16, color=colorname)

    return results, blue_interp, red_interp, green_interp, cyan_interp
