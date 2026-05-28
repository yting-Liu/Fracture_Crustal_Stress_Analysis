import re
import glob
from pathlib import Path
import numpy as np

# ============================================================
# User parameters
# ============================================================

ORGANIZE_PATTERN = "../organize_wid_amp_shear_normal/*_profile_result.txt"
PROFILE_PATTERN = "../profiles/*"

HALF_WIDTH = 200.0
DX = 20.0

OUTPUT_TXT = "profile_symmetry.txt"


# ============================================================
# Utility functions
# ============================================================

def extract_id_from_name(filepath: str) -> str:
    name = Path(filepath).name
    m = re.match(r"^(\d+)_", name)
    if not m:
        raise ValueError(f"Unable to extract ID from filename: {name}")
    return m.group(1)


def parse_left_right_points(result_file: str):
    with open(result_file, "r", encoding="utf-8") as f:
        text = f.read()

    left_match = re.search(
        r"Left Point:\s*\(\s*([-\d.eE+]+)\s*,\s*([-\d.eE+]+)\s*\)", text
    )
    right_match = re.search(
        r"Right Point:\s*\(\s*([-\d.eE+]+)\s*,\s*([-\d.eE+]+)\s*\)", text
    )

    if left_match is None or right_match is None:
        raise ValueError(f"Unable to parse Left/Right Point: {result_file}")

    xL = float(left_match.group(1))
    yL = float(left_match.group(2))
    xR = float(right_match.group(1))
    yR = float(right_match.group(2))
    return xL, yL, xR, yR


def find_file_by_id(file_id: str, file_list: list[str]) -> str:
    matched = []
    for f in file_list:
        try:
            fid = extract_id_from_name(f)
            if fid == file_id:
                matched.append(f)
        except Exception:
            continue

    if len(matched) == 0:
        raise FileNotFoundError(f"No file found for ID {file_id}")
    if len(matched) > 1:
        print(f"[Warning] ID {file_id} matched multiple files; using the first one by default: {matched[0]}")
    return matched[0]


def load_profile_xy(profile_file: str):
    data = np.loadtxt(profile_file)

    if data.ndim == 1:
        data = data.reshape(1, -1)

    if data.shape[1] < 2:
        raise ValueError(f"The file should contain at least two columns of data: {profile_file}")

    x = data[:, 0]
    y = data[:, 1]

    valid = np.isfinite(x) & np.isfinite(y)
    x = x[valid]
    y = y[valid]

    if len(x) < 2:
        raise ValueError(f"Insufficient valid data points: {profile_file}")

    idx = np.argsort(x)
    return x[idx], y[idx]


def interp_linear(x, y, xq):
    return np.interp(xq, x, y, left=np.nan, right=np.nan)


def compute_abs_symmetry_centered(x_rel, y_rel, half_width=200.0, dx=20.0):
    """
    Compute the left-right absolute-value symmetry for a profile that has
    already been shifted to the new origin:
        |y(-d)| ≈ |y(+d)|
    """
    d = np.arange(0.0, half_width + dx, dx)

    x_left = -d
    x_right = +d

    y_left = interp_linear(x_rel, y_rel, x_left)
    y_right = interp_linear(x_rel, y_rel, x_right)

    valid = np.isfinite(y_left) & np.isfinite(y_right)
    d_valid = d[valid]
    y_left_valid = y_left[valid]
    y_right_valid = y_right[valid]

    if len(d_valid) < 2:
        raise ValueError("Too few valid points for symmetry comparison")

    abs_left = np.abs(y_left_valid)
    abs_right = np.abs(y_right_valid)

    diff_abs = abs_right - abs_left

    mad = np.mean(np.abs(diff_abs))
    rmsd = np.sqrt(np.mean(diff_abs ** 2))

    denom = np.sum(abs_left + abs_right)
    S = np.nan if denom == 0 else 1.0 - np.sum(np.abs(diff_abs)) / denom

    if np.std(abs_left) > 0 and np.std(abs_right) > 0:
        corr_abs = np.corrcoef(abs_left, abs_right)[0, 1]
    else:
        corr_abs = np.nan

    return {
        "n_valid": len(d_valid),
        "MAD": mad,
        "RMSD": rmsd,
        "S": S,
        "corr_abs": corr_abs,
    }



# ============================================================
# Main
# ============================================================

def main():
    organize_files = sorted(glob.glob(ORGANIZE_PATTERN))
    profile_files = sorted(glob.glob(PROFILE_PATTERN))

    if len(organize_files) == 0:
        raise FileNotFoundError(f"No organize files found: {ORGANIZE_PATTERN}")
    if len(profile_files) == 0:
        raise FileNotFoundError(f"No profile files found: {PROFILE_PATTERN}")

    ids_all = []
    for f in organize_files:
        try:
            ids_all.append(extract_id_from_name(f))
        except Exception:
            continue
    ids_all = sorted(set(ids_all))

    print(f"Total number of profiles to recompute: {len(ids_all)}")

    results = {}
    n_computed = 0
    n_failed = 0

    for pid in ids_all:
        try:
            org_file = find_file_by_id(pid, organize_files)
            profile_file = find_file_by_id(pid, profile_files)

            xL, yL, xR, yR = parse_left_right_points(org_file)
            xc = 0.5 * (xL + xR)
            yc = 0.5 * (yL + yR)

            x, y = load_profile_xy(profile_file)

            # Use the midpoint of the left and right jump points as the new origin
            x_rel = x - xc
            y_rel = y - yc

            sym = compute_abs_symmetry_centered(
                x_rel, y_rel,
                half_width=HALF_WIDTH,
                dx=DX,
            )

            results[pid] = {
                "ID": pid,
                "xL": xL,
                "xR": xR,
                "xc": xc,
                "n_valid": sym["n_valid"],
                "MAD": sym["MAD"],
                "RMSD": sym["RMSD"],
                "S": sym["S"],
                "corr_abs": sym["corr_abs"],
                "status": "OK",
            }
            n_computed += 1

        except Exception as e:
            print(f"[FAIL] {pid}: {e}")
            results[pid] = {
                "ID": pid,
                "xL": np.nan,
                "xR": np.nan,
                "xc": np.nan,
                "n_valid": 0,
                "MAD": np.nan,
                "RMSD": np.nan,
                "S": np.nan,
                "corr_abs": np.nan,
                "status": "FAIL",
            }
            n_failed += 1

    # Compute overall mean values
    rows_ok = [results[pid] for pid in ids_all if results[pid]["status"] == "OK"]
    mean_MAD = np.nanmean([r["MAD"] for r in rows_ok]) if rows_ok else np.nan
    mean_RMSD = np.nanmean([r["RMSD"] for r in rows_ok]) if rows_ok else np.nan
    mean_S = np.nanmean([r["S"] for r in rows_ok]) if rows_ok else np.nan
    mean_corr_abs = np.nanmean([r["corr_abs"] for r in rows_ok]) if rows_ok else np.nan

    with open(OUTPUT_TXT, "w", encoding="utf-8") as f:
        f.write("Symmetry table\n")
        f.write("Profiles were recentered by midpoint of picked jumps (xc, yc)\n")
        f.write("=" * 120 + "\n")
        f.write(
            f"{'ID':<8}"
            f"{'xL':>12}"
            f"{'xR':>12}"
            f"{'xc':>12}"
            f"{'n_valid':>10}"
            f"{'MAD':>12}"
            f"{'RMSD':>12}"
            f"{'S':>12}"
            f"{'corr_abs':>14}"
            f"  status\n"
        )
        f.write("-" * 120 + "\n")

        for pid in ids_all:
            r = results[pid]
            f.write(f"{r['ID']:<8}")
            f.write(f"{r['xL']:>12.3f}" if np.isfinite(r["xL"]) else f"{'nan':>12}")
            f.write(f"{r['xR']:>12.3f}" if np.isfinite(r["xR"]) else f"{'nan':>12}")
            f.write(f"{r['xc']:>12.3f}" if np.isfinite(r["xc"]) else f"{'nan':>12}")
            f.write(f"{int(r['n_valid']):>10}")
            f.write(f"{r['MAD']:>12.6f}" if np.isfinite(r["MAD"]) else f"{'nan':>12}")
            f.write(f"{r['RMSD']:>12.6f}" if np.isfinite(r["RMSD"]) else f"{'nan':>12}")
            f.write(f"{r['S']:>12.6f}" if np.isfinite(r["S"]) else f"{'nan':>12}")
            f.write(f"{r['corr_abs']:>14.6f}" if np.isfinite(r["corr_abs"]) else f"{'nan':>14}")
            f.write(f"  {r['status']}\n")

        f.write("\n")
        f.write("=" * 120 + "\n")
        f.write("Summary\n")
        f.write("=" * 120 + "\n")
        f.write(f"Total profiles                       : {len(ids_all)}\n")
        f.write(f"Profiles failed : {n_failed}\n")
        f.write(f"Half width                           : {HALF_WIDTH}\n")
        f.write(f"Interpolation step dx                : {DX}\n")
        f.write("\n")
        f.write("Overall statistics (mean of per-profile values)\n")
        f.write(f"  mean MAD       = {mean_MAD:.6f}\n")
        f.write(f"  mean RMSD      = {mean_RMSD:.6f}\n")
        f.write(f"  mean S         = {mean_S:.6f}\n")
        f.write(f"  mean corr_abs  = {mean_corr_abs:.6f}\n")

    print(f"\nDone. Results have been written to: {OUTPUT_TXT}")
    print(f"Total number of profiles: {len(ids_all)}")
    print(f"Profiles failed: {n_failed}")
    print(f"Overall mean S = {mean_S:.6f}" if np.isfinite(mean_S) else "Overall mean S = nan")


if __name__ == "__main__":
    main()
