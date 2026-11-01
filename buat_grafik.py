
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# Lokasi data dan hasil grafik
folder = Path("results/validation")
file_csv = folder / "data-grafik.csv"

# Baca hasil pengujian
df = pd.read_csv(file_csv)

# Pastikan tipe data benar
df["VU"] = pd.to_numeric(df["VU"], errors="coerce")
df["RPS"] = pd.to_numeric(df["RPS"], errors="coerce")
df["P95_ms"] = pd.to_numeric(df["P95_ms"], errors="coerce")
df["Config"] = df["Config"].astype(str).str.upper()

df = df.dropna(subset=["VU", "RPS", "P95_ms"])
df = df.sort_values(["Config", "VU"])

# Grafik 1: Throughput
plt.figure(figsize=(9, 5))

for config in ["A", "B", "C"]:
    data = df[df["Config"] == config]
    if not data.empty:
        plt.plot(
            data["VU"], data["RPS"],
            marker="o", label=f"Config {config}"
        )

plt.title("Perbandingan Throughput")
plt.xlabel("Virtual Users (VU)")
plt.ylabel("Throughput (requests/second)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig(folder / "grafik-throughput.png", dpi=200)
plt.close()

# Grafik 2: P95 Latency
plt.figure(figsize=(9, 5))

for config in ["A", "B", "C"]:
    data = df[df["Config"] == config]
    if not data.empty:
        plt.plot(
            data["VU"], data["P95_ms"],
            marker="o", label=f"Config {config}"
        )

plt.title("Perbandingan P95 Latency")
plt.xlabel("Virtual Users (VU)")
plt.ylabel("P95 Latency (ms)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig(folder / "grafik-p95-latency.png", dpi=200)
plt.close()

print("Grafik berhasil dibuat!")
print("Lokasi hasil:")
print(folder / "grafik-throughput.png")
print(folder / "grafik-p95-latency.png")
