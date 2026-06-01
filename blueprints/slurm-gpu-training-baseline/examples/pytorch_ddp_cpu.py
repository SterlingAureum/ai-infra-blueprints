#!/usr/bin/env python3

import os
import socket

import torch
import torch.distributed as dist


def get_env_int(name: str, default: int = 0) -> int:
    value = os.environ.get(name)
    if value is None:
        return default
    return int(value)


def main() -> None:
    # Slurm provides SLURM_PROCID and SLURM_NTASKS for each task.
    rank = get_env_int("SLURM_PROCID", 0)
    world_size = get_env_int("WORLD_SIZE", get_env_int("SLURM_NTASKS", 1))
    local_id = get_env_int("SLURM_LOCALID", 0)

    master_addr = os.environ.get("MASTER_ADDR", "127.0.0.1")
    master_port = os.environ.get("MASTER_PORT", "29500")

    os.environ["RANK"] = str(rank)
    os.environ["WORLD_SIZE"] = str(world_size)
    os.environ["MASTER_ADDR"] = master_addr
    os.environ["MASTER_PORT"] = master_port

    hostname = socket.gethostname()

    print(
        f"[before init] hostname={hostname} "
        f"rank={rank} local_id={local_id} world_size={world_size} "
        f"master={master_addr}:{master_port}",
        flush=True,
    )

    dist.init_process_group(
        backend="gloo",
        init_method="env://",
        rank=rank,
        world_size=world_size,
    )

    value = torch.tensor([rank], dtype=torch.float32)
    dist.all_reduce(value, op=dist.ReduceOp.SUM)

    print(
        f"[after all_reduce] hostname={hostname} "
        f"rank={rank}/{world_size} reduced_value={value.item()}",
        flush=True,
    )

    dist.destroy_process_group()


if __name__ == "__main__":
    main()
