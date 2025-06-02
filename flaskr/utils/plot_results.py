import numpy as np
import matplotlib.pyplot as plt
import os


def run(results_table, a_blue, a_red, a_green, a_cyan, marker_names, num_sets, output_dir):
    print("Plotting the histograms.")
    x = np.linspace(0, 1, 10000)
    os.makedirs(output_dir, exist_ok=True)

    for i in range(num_sets):
        if np.all(a_blue[i] == 0) and np.all(a_red[i] == 0) and np.all(a_green[i] == 0) and (not marker_names.get("cyan") or np.all(a_cyan[i] == 0)):
            print(f"Skipping plot for set {i + 1} — no data.")
            continue

        fig, ax = plt.subplots(figsize=(10, 4))
        ax.set_title(results_table[i + 1][0], fontsize=14, weight='bold')
        ax.plot(x, a_blue[i], 'b', label='DAPI')
        ax.plot(x, a_red[i], 'r', label=marker_names['red'])
        ax.plot(x, a_green[i], 'g', label=marker_names['green'])
        if marker_names.get("cyan") and not np.all(a_cyan[i] == 0):
            ax.plot(x, a_cyan[i], 'c', label=marker_names['cyan'])
        ax.set_ylim((0, 1))
        ax.set_xlabel('Relative Length (Anterior to Posterior)')
        ax.set_ylabel('Normalized Intensity')
        ax.legend()
        plt.tight_layout()
        fig_path = os.path.join(output_dir, f"set_{i + 1}.png")
        fig.savefig(fig_path)
        plt.close(fig)


    print("Generating final plots.")

    fig, ax = plt.subplots()
    for i in range(num_sets):
        ax.plot(x, a_blue[i], color='black', linewidth=0.5)
    ax.plot(x, results_table[-1][1], color='blue', linewidth=2)
    ax.set_title("DAPI", color='blue', fontsize=20)
    ax.set_xlabel("Relative Length (Anterior to Posterior)")
    ax.set_ylabel("Normalized Intensity")
    plt.tight_layout()
    fig.savefig(os.path.join(output_dir, "average_dapi.png"))
    plt.close(fig)

    fig, ax = plt.subplots()
    for i in range(num_sets):
        ax.plot(x, a_red[i], color='black', linewidth=0.5)
    ax.plot(x, results_table[-1][2], color='red', linewidth=2)
    ax.set_title(marker_names['red'], color='red', fontsize=20)
    ax.set_xlabel("Relative Length (Anterior to Posterior)")
    ax.set_ylabel("Normalized Intensity")
    plt.tight_layout()
    fig.savefig(os.path.join(output_dir, "average_red.png"))
    plt.close(fig)

    fig, ax = plt.subplots()
    for i in range(num_sets):
        ax.plot(x, a_green[i], color='black', linewidth=0.5)
    ax.plot(x, results_table[-1][3], color='green', linewidth=2)
    ax.set_title(marker_names['green'], color='green', fontsize=20)
    ax.set_xlabel("Relative Length (Anterior to Posterior)")
    ax.set_ylabel("Normalized Intensity")
    plt.tight_layout()
    fig.savefig(os.path.join(output_dir, "average_green.png"))
    plt.close(fig)

    if marker_names.get("cyan"):
        fig, ax = plt.subplots()
        for i in range(num_sets):
            ax.plot(x, a_cyan[i], color='black', linewidth=0.5)
        ax.plot(x, results_table[-1][4], color='cyan', linewidth=2)
        ax.set_title(marker_names['cyan'], color='cyan', fontsize=20)
        ax.set_xlabel("Relative Length (Anterior to Posterior)")
        ax.set_ylabel("Normalized Intensity")
        plt.tight_layout()
        fig.savefig(os.path.join(output_dir, "average_cyan.png"))
        plt.close(fig)

    print("Analysis complete.")
