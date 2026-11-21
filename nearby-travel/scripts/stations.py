#!/usr/bin/env python3
"""Read or refresh the local 12306 railway station index."""

import argparse
import datetime as dt
import json
import re
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "data" / "12306-stations.json"
VERIFIED = ROOT / "data" / "verified-cities.json"
SOURCE = "https://kyfw.12306.cn/otn/resources/js/framework/station_name.js"


def refresh():
    request = urllib.request.Request(SOURCE, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=25) as response:
        raw = response.read().decode("utf-8-sig")
    match = re.search(r"var\s+station_names\s*=\s*'([^']*)'", raw)
    if not match:
        raise ValueError("12306 数据格式无法识别；原索引未被覆盖")
    stations = []
    for record in match.group(1).split("@")[1:]:
        parts = record.split("|")
        if len(parts) < 8 or not parts[1] or not parts[2] or not parts[7]:
            raise ValueError("12306 车站记录不完整；原索引未被覆盖")
        stations.append({"name": parts[1], "code": parts[2], "city": parts[7]})
    if len(stations) < 3000 or len({item["code"] for item in stations}) < 3000:
        raise ValueError("12306 车站数量异常；原索引未被覆盖")
    document = {
        "source": SOURCE,
        "retrieved_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "scope": "12306 station-name code table; may include inactive stations",
        "stations": stations,
    }
    INDEX.parent.mkdir(parents=True, exist_ok=True)
    temp = INDEX.with_suffix(".tmp")
    temp.write_text(json.dumps(document, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    temp.replace(INDEX)
    print(json.dumps({"stations": len(stations), "cities": len({x["city"] for x in stations}), "retrieved_utc": document["retrieved_utc"]}, ensure_ascii=False))


def list_stations(city):
    if city.endswith("市"):
        city = city[:-1]
    document = json.loads(INDEX.read_text(encoding="utf-8"))
    matches = [item for item in document["stations"] if item["city"] == city]
    verified = json.loads(VERIFIED.read_text(encoding="utf-8")).get(city)
    if verified:
        names = set(verified["names"])
        matches = [item for item in matches if item["name"] in names]
        missing = names - {item["name"] for item in matches}
        if missing:
            raise ValueError(f"已核实名单与 12306 索引不一致: {sorted(missing)}")
    print(json.dumps({
        "city": city,
        "source": verified["source"] if verified else document["source"],
        "retrieved_utc": document["retrieved_utc"],
        "status": "verified_city_list" if verified else "12306_candidates_check_current_service",
        "stations": matches,
    }, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("update", help="从 12306 官网刷新全国车站索引")
    listing = sub.add_parser("list", help="按 12306 城市分组读取本地名单")
    listing.add_argument("--city", required=True, help="12306 城市名，例如 上海")
    args = parser.parse_args()
    refresh() if args.command == "update" else list_stations(args.city)


if __name__ == "__main__":
    main()
