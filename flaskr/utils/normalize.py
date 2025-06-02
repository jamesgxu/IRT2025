import numpy as np

def run(results_table, blue_interpolate, red_interpolate, green_interpolate, cyan_interpolate):
    num_sets = blue_interpolate.shape[0]
    print("Normalizing the data to the max intensity of all of the images per channel.")

    blue_interpolate[np.isnan(blue_interpolate)] = 0
    red_interpolate[np.isnan(red_interpolate)] = 0
    green_interpolate[np.isnan(green_interpolate)] = 0
    cyan_interpolate[np.isnan(cyan_interpolate)] = 0

    blue_all_max = np.max(blue_interpolate)
    red_all_max = np.max(red_interpolate)
    green_all_max = np.max(green_interpolate)
    cyan_all_max = np.max(cyan_interpolate)

    a_blue_results = blue_interpolate / blue_all_max if blue_all_max != 0 else blue_interpolate
    a_red_results = red_interpolate / red_all_max if red_all_max != 0 else red_interpolate
    a_green_results = green_interpolate / green_all_max if green_all_max != 0 else green_interpolate
    a_cyan_results = cyan_interpolate / cyan_all_max if cyan_all_max != 0 else cyan_interpolate

    blue_col_avg = np.sum(a_blue_results, axis=0) / num_sets
    red_col_avg = np.sum(a_red_results, axis=0) / num_sets
    green_col_avg = np.sum(a_green_results, axis=0) / num_sets
    cyan_col_avg = np.sum(a_cyan_results, axis=0) / num_sets

    results_table[-1][1] = blue_col_avg
    results_table[-1][2] = red_col_avg
    results_table[-1][3] = green_col_avg
    results_table[-1][4] = cyan_col_avg

    for i in range(num_sets):
        results_table[i + 1][1] = a_blue_results[i, :]
        results_table[i + 1][2] = a_red_results[i, :]
        results_table[i + 1][3] = a_green_results[i, :]
        results_table[i + 1][4] = a_cyan_results[i, :]

    return results_table, a_blue_results, a_red_results, a_green_results, a_cyan_results
