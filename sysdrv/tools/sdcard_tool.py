import argparse
from dataclasses import dataclass
import re
import shlex
import sys


@dataclass
class Partition:
    name: str
    offset: int
    size: int | None

    def pretty(self):
        if self.size is not None:
            return f"{self.name}: {self.offset:02x}/{self.size:02x}"
        else:
            return f"{self.name}: {self.offset:02x}/-"

    def dd_write_command(self, target: str) -> list[str]:
        base = [
            "dd",
            f"if={self.name}.img",
            f"of={target}",
            f"oseek={self.offset}",
            "oflag=seek_bytes",
            "status=progress",
            "conv=fsync",
        ]
        count = (
            [f"count={self.size}", "iflag=count_bytes"] if self.size is not None else []
        )
        return base + count

    def dd_read_command(self, source: str) -> list[str]:
        base = [
            "dd",
            f"if={source}",
            f"of={self.name}.img",
            f"iseek={self.offset}",
            "iflag=skip_bytes",
            "status=progress",
        ]
        count = (
            [f"count={self.size}", "iflag=count_bytes"] if self.size is not None else []
        )
        return base + count


def ext_size(size: bytes | None, suffix: bytes | None):
    if size is None:
        return None

    s = int(size)
    multiplier = {
        b"K": 2**10,
        b"M": 2**20,
        b"G": 2**30,
        b"T": 2**40,
        b"P": 2**50,
        b"E": 2**60,
        None: 1,
    }[suffix]
    return s * multiplier


def parse_env(blk: bytes) -> list[Partition]:
    blk, _ = blk.split(b"\0", maxsplit=1)
    _, mmcblk = blk.split(b"blkdevparts=", maxsplit=1)
    print(mmcblk.decode('utf-8'), file=sys.stderr)
    mmblk_dev, line = mmcblk.split(b":")
    parts = line.split(b",")

    result = []
    cur_offset = 0
    for part in parts:
        groups = re.match(
            rb"(?:(\d+)([KMGTPE])?(?:@(\d+)([KMGTPE])?)?|(-))\((.*)\)", part
        ).groups()
        size, size_suffix, offset, offset_suffix, minus, name = groups

        act_size = ext_size(size, size_suffix)
        act_offset = ext_size(offset, offset_suffix)
        # off = act_offset or 0
        off = 0 # Okay for some reason the offset break everything so we ignore it

        result.append(Partition(name=name.decode('utf-8'), offset=cur_offset + off, size=act_size))
        if act_size is not None:
            # None for "-"
            cur_offset += act_size + off
        print(result[-1].pretty(), file=sys.stderr)
    return result


def parse_env_file(file: str = "./env.img") -> list[Partition]:
    with open(file, "rb") as f:
        buf = f.read(2**10)
        return parse_env(buf)


def make_dd(parts: list[Partition], dev: str, write: bool):
    return "\n".join(
        shlex.join(p.dd_write_command(dev) if write else p.dd_read_command(dev))
        for p in parts
    )


def pack(dev: str):
    p = parse_env_file()
    print(make_dd(p, dev, True))


def unpack(dev: str):
    p = parse_env_file(dev)
    print(make_dd(p, dev, False))


def main():
    parser = argparse.ArgumentParser(
        description="A tool for packing and unpacking data to/from devices."
    )

    subparsers = parser.add_subparsers(dest="command")

    # Subcommand: pack
    pack_parser = subparsers.add_parser(
        "pack", help="Pack data to the specified device"
    )
    pack_parser.add_argument("device", type=str, help="The device path to pack data to")

    # Subcommand: unpack
    unpack_parser = subparsers.add_parser(
        "unpack", help="Unpack data from the specified device"
    )
    unpack_parser.add_argument(
        "device", type=str, help="The device path to unpack data from"
    )

    args = parser.parse_args()
    if args.command == "pack":
        pack(args.device)
    elif args.command == "unpack":
        unpack(args.device)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
