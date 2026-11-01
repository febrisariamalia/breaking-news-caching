import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Lokasi file
base_dir = Path("results/validation")
csv_file = base_dir / "rekap-hasil-250-500-1000.csv"
output_dir = base_dir / "grafik"
output_dir.mkdir(parents=True, exist_ok=True)

# Baca data dan pilih pengujian utama
df = pd.read_csv(csv_file)
df = df[df["VUs"].isin([250, 500, 1000])].copy()
df = df.sort_values(["VUs", "Config"])

configs = ["A", "B", "C"]
vus_levels = [250, 500, 1000]

# Grafik 1: Throughput
plt.figure(figsize=(10, 6))

for config in configs:
    subset = df[df["Config"] == config].sort_values("VUs")
    plt.plot(
        subset["VUs"],
        subset["Throughput"],
        marker="o",
        linewidth=2,
        label=f"Config {config}"
    )

plt.title("Throughput Comparison - Cache Hit Scenario")
plt.xlabel("Virtual Users (VU)")
plt.ylabel("Throughput (requests/second)")
plt.xticks(vus_levels)
plt.grid(True, linestyle="--", alpha=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(output_dir / "throughput.png", dpi=300)
plt.close()

# Grafik 2: P95 Latency
plt.figure(figsize=(10, 6))

for config in configs:
    subset = df[df["Config"] == config].sort_values("VUs")
    plt.plot(
        subset["VUs"],
        subset["P95LatencyMs"],
        marker="o",
        linewidth=2,
        label=f"Config {config}"
    )

plt.title("P95 Latency Comparison - Cache Hit Scenario")
plt.xlabel("Virtual Users (VU)")
plt.ylabel("P95 Latency (milliseconds)")
plt.xticks(vus_levels)
plt.grid(True, linestyle="--", alpha=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(output_dir / "p95-latency.png", dpi=300)
plt.close()

print("Grafik berhasil dibuat:")
print(output_dir / "throughput.png")
print(output_dir / "p95-latency.png")

print("\nData yang digunakan:")
print(df[["Config", "VUs", "Throughput", "P95LatencyMs"]].to_string(index=False))
