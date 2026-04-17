import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots

def load_results(path="data/processed/simulation_results.csv"):
    return pd.read_csv(path)

def cycle_time_distribution(df):
    fig = px.histogram(df, x="cycle_time", color="order_type", barmode="overlay",
                       title="Order Cycle Time Distribution", nbins=50,
                       labels={"cycle_time": "Cycle Time (min)"})
    return fig

def throughput_timeline(df):
    df["hour"] = (df["stage_completed"] / 60).astype(int)
    hourly = df.groupby("hour").size().reset_index(name="orders")
    fig = px.line(hourly, x="hour", y="orders", title="Throughput Over Time",
                  labels={"hour": "Hour", "orders": "Orders Completed"})
    return fig

def resource_utilization(df):
    stages = ["validation", "picking", "packing", "qa", "shipping"]
    busy_times = {}
    for stage in stages:
        start = f"stage_{stage}_start"
        end = f"stage_{stage}_end"
        if start in df.columns and end in df.columns:
            busy = (df[end] - df[start]).dropna().sum()
            busy_times[stage] = busy
    total_time = df["stage_completed"].max()
    capacities = {"validation": 5, "picking": 8, "packing": 6, "qa": 2, "shipping": 3}
    util = {s: busy_times.get(s, 0) / (total_time * capacities.get(s, 1)) * 100
            for s in stages}
    fig = px.bar(x=list(util.keys()), y=list(util.values()),
                 title="Resource Utilization (%)",
                 labels={"x": "Stage", "y": "Utilization %"})
    return fig

def bottleneck_analysis(df):
    stages = ["validation", "picking", "packing", "qa", "shipping"]
    wait_times = {}
    for i, stage in enumerate(stages):
        start = f"stage_{stage}_start"
        if i == 0:
            prev_end = "stage_validation_start"
        else:
            prev_end = f"stage_{stages[i-1]}_end"
        if start in df.columns and prev_end in df.columns:
            wait = (df[start] - df[prev_end]).dropna()
            wait_times[stage] = {"mean": wait.mean(), "p95": wait.quantile(0.95)}
    return wait_times

def generate_report(df, output_dir="reports"):
    import os
    os.makedirs(output_dir, exist_ok=True)
    cycle_time_distribution(df).write_html(f"{output_dir}/cycle_time_dist.html")
    throughput_timeline(df).write_html(f"{output_dir}/throughput.html")
    resource_utilization(df).write_html(f"{output_dir}/utilization.html")
    bottlenecks = bottleneck_analysis(df)
    print("Bottleneck Analysis (avg wait time in min):")
    for stage, times in bottlenecks.items():
        print(f"  {stage}: mean={times['mean']:.1f}, p95={times['p95']:.1f}")
    print(f"Reports saved to {output_dir}/")


if __name__ == "__main__":
    df = load_results()
    generate_report(df)
