import simpy
import random
import yaml
import pandas as pd
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

@dataclass
class Order:
    id: int
    order_type: str
    item_count: int
    priority: int
    created_at: float
    timestamps: dict = field(default_factory=dict)

class OrderJourneySimulation:
    def __init__(self, config_path="config/simulation.yaml"):
        with open(config_path) as f:
            self.config = yaml.safe_load(f)
        self.env = simpy.Environment()
        self.results = []
        self.queue_logs = []
        self._setup_resources()

    def _setup_resources(self):
        cfg = {r["name"]: r["capacity"] for r in self.config["resources"]}
        self.order_processor = simpy.Resource(self.env, capacity=cfg.get("OrderProcessor", 5))
        self.pick_station = simpy.Resource(self.env, capacity=cfg.get("PickStation", 8))
        self.pack_station = simpy.Resource(self.env, capacity=cfg.get("PackStation", 6))
        self.qa_inspector = simpy.Resource(self.env, capacity=cfg.get("QAInspector", 2))
        self.shipping_dock = simpy.Resource(self.env, capacity=cfg.get("ShippingDock", 3))

    def _triangular(self, low, mode, high):
        return random.triangular(low, high, mode)

    def order_process(self, order):
        order.timestamps["validation_start"] = self.env.now
        with self.order_processor.request() as req:
            yield req
            yield self.env.timeout(self._triangular(1, 3, 8))
        order.timestamps["validation_end"] = self.env.now

        order.timestamps["picking_start"] = self.env.now
        with self.pick_station.request() as req:
            yield req
            base = self._triangular(5, 10, 20)
            yield self.env.timeout(base * (1 + 0.1 * order.item_count))
        order.timestamps["picking_end"] = self.env.now

        order.timestamps["packing_start"] = self.env.now
        with self.pack_station.request() as req:
            yield req
            yield self.env.timeout(self._triangular(3, 7, 15))
        order.timestamps["packing_end"] = self.env.now

        if random.random() < 0.3:
            order.timestamps["qa_start"] = self.env.now
            with self.qa_inspector.request() as req:
                yield req
                yield self.env.timeout(random.uniform(2, 5))
            order.timestamps["qa_end"] = self.env.now

        order.timestamps["shipping_start"] = self.env.now
        with self.shipping_dock.request() as req:
            yield req
            yield self.env.timeout(self._triangular(2, 5, 10))
        order.timestamps["shipping_end"] = self.env.now
        order.timestamps["completed"] = self.env.now

        self.results.append({
            "order_id": order.id,
            "order_type": order.type,
            "item_count": order.item_count,
            "priority": order.priority,
            "cycle_time": order.timestamps["completed"] - order.created_at,
            **{f"stage_{k}": v for k, v in order.timestamps.items()},
        })

    def order_generator(self):
        order_id = 0
        while True:
            yield self.env.timeout(random.expovariate(1/2))
            order_id += 1
            order = Order(
                id=order_id,
                order_type=random.choice(["standard", "express", "bulk"]),
                item_count=random.randint(1, 20),
                priority=random.choices([1, 2, 3], weights=[0.6, 0.3, 0.1])[0],
                created_at=self.env.now,
            )
            self.env.process(self.order_process(order))

    def run(self, duration=None):
        if duration is None:
            duration = self.config["simulation"]["run_length"]
        self.env.process(self.order_generator())
        self.env.run(until=duration)
        return pd.DataFrame(self.results)

    def summary(self, df=None):
        if df is None:
            df = self.run()
        return {
            "total_orders": len(df),
            "avg_cycle_time": df["cycle_time"].mean(),
            "median_cycle_time": df["cycle_time"].median(),
            "p95_cycle_time": df["cycle_time"].quantile(0.95),
            "throughput_per_hour": len(df) / (df["stage_completed"].max() / 60),
            "by_type": df.groupby("order_type")["cycle_time"].mean().to_dict(),
        }


if __name__ == "__main__":
    sim = OrderJourneySimulation()
    df = sim.run()
    stats = sim.summary(df)
    print(f"Orders processed: {stats['total_orders']}")
    print(f"Avg cycle time: {stats['avg_cycle_time']:.1f} min")
    print(f"Median cycle time: {stats['median_cycle_time']:.1f} min")
    print(f"P95 cycle time: {stats['p95_cycle_time']:.1f} min")
    print(f"Throughput: {stats['throughput_per_hour']:.1f} orders/hr")
    print(f"By type: {stats['by_type']}")
    df.to_csv("data/processed/simulation_results.csv", index=False)
    print("Results saved to data/processed/simulation_results.csv")
