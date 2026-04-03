"""drawio PFDの矢印-オブジェクト交差チェッカー + 自動修正
矢印の直線経路がオブジェクトのバウンディングボックスと交差する場合を検出し、
オブジェクトの配置を調整して解消する。
"""

import copy
import shutil
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Rect:
    """オブジェクトのバウンディングボックス"""
    id: str
    x: float
    y: float
    w: float
    h: float
    label: str = ""

    @property
    def cx(self) -> float:
        return self.x + self.w / 2

    @property
    def cy(self) -> float:
        return self.y + self.h / 2

    @property
    def right(self) -> float:
        return self.x + self.w

    @property
    def bottom(self) -> float:
        return self.y + self.h


@dataclass
class Edge:
    """矢印"""
    id: str
    source: str
    target: str


def parse_drawio(path: str) -> tuple[dict[str, Rect], list[Edge], dict[str, str], dict[str, Rect]]:
    """drawioファイルからオブジェクト、矢印、矢印スタイル、グループ枠を抽出する。"""
    tree = ET.parse(path)
    root = tree.getroot()

    objects: dict[str, Rect] = {}
    edges: list[Edge] = []
    edge_styles: dict[str, str] = {}
    groups: dict[str, Rect] = {}

    for cell in root.iter("mxCell"):
        cell_id = cell.get("id", "")
        style = cell.get("style", "")
        value = cell.get("value", "")
        geo = cell.find("mxGeometry")

        # グループ枠
        if ("dashed=1;fillColor=none" in style or "dashed=1;fillColor=" in style) and "rounded=1" in style:
            if geo is not None:
                x = float(geo.get("x", 0))
                y = float(geo.get("y", 0))
                w = float(geo.get("width", 0))
                h = float(geo.get("height", 0))
                label = value.replace("&#xa;", " ").replace("\n", " ").strip()
                groups[cell_id] = Rect(cell_id, x, y, w, h, label)
            continue

        if geo is not None and cell.get("vertex") == "1":
            x = float(geo.get("x", 0))
            y = float(geo.get("y", 0))
            w = float(geo.get("width", 0))
            h = float(geo.get("height", 0))
            label = value.replace("&#xa;", " ").replace("\n", " ").strip()
            objects[cell_id] = Rect(cell_id, x, y, w, h, label)

        elif cell.get("edge") == "1":
            source = cell.get("source", "")
            target = cell.get("target", "")
            if source and target:
                edges.append(Edge(cell_id, source, target))
                edge_styles[cell_id] = style

    return objects, edges, edge_styles, groups


def line_intersects_rect(x1: float, y1: float, x2: float, y2: float, rect: Rect, margin: float = 8) -> bool:
    """線分(x1,y1)-(x2,y2)が矩形と交差するかチェック。
    Liang-Barskyアルゴリズムで判定。marginは矩形を外側に膨らませてスレスレを防止。"""
    dx = x2 - x1
    dy = y2 - y1

    # 矩形の境界（marginで膨張）
    xmin = rect.x - margin
    xmax = rect.right + margin
    ymin = rect.y - margin
    ymax = rect.bottom + margin

    p = [-dx, dx, -dy, dy]
    q = [x1 - xmin, xmax - x1, y1 - ymin, ymax - y1]

    t0 = 0.0
    t1 = 1.0

    for pi, qi in zip(p, q):
        if abs(pi) < 1e-10:
            if qi < 0:
                return False
        else:
            t = qi / pi
            if pi < 0:
                t0 = max(t0, t)
            else:
                t1 = min(t1, t)
            if t0 > t1:
                return False

    return True


def check_overlaps(objects: dict[str, Rect], edges: list[Edge], edge_styles: dict[str, str]) -> list[dict]:
    """直線矢印のみ、ソース/ターゲット以外のオブジェクトとの交差をチェック。
    orthogonalEdgeStyleの矢印は折れ線で回避可能なので除外する。"""
    issues = []

    for edge in edges:
        # orthogonal（折れ線）矢印はスキップ
        style = edge_styles.get(edge.id, "")
        if "orthogonalEdgeStyle" in style:
            continue

        src = objects.get(edge.source)
        tgt = objects.get(edge.target)
        if not src or not tgt:
            continue

        for obj_id, obj in objects.items():
            if obj_id in (edge.source, edge.target):
                continue

            if line_intersects_rect(src.cx, src.cy, tgt.cx, tgt.cy, obj):
                issues.append({
                    "edge": edge.id,
                    "source": f"{src.label[:30]} ({edge.source})",
                    "target": f"{tgt.label[:30]} ({edge.target})",
                    "blocked_by": f"{obj.label[:30]} ({obj_id})",
                    "blocked_obj_id": obj_id,
                    "blocked_rect": (obj.x, obj.y, obj.w, obj.h),
                    "src_pos": (src.cx, src.cy),
                    "tgt_pos": (tgt.cx, tgt.cy),
                })

    return issues


def check_group_overflow(objects: dict[str, Rect], groups: dict[str, Rect], margin: float = 15) -> list[dict]:
    """オブジェクトがグループ枠からはみ出していないかチェック。"""
    issues = []

    for grp_id, grp in groups.items():
        for obj_id, obj in objects.items():
            # オブジェクトの中心がグループ内にあるものを対象
            if not (grp.x <= obj.cx <= grp.right and grp.y <= obj.cy <= grp.bottom):
                continue

            overflow = {}
            if obj.x < grp.x + margin:
                overflow["left"] = grp.x + margin - obj.x
            if obj.right > grp.right - margin:
                overflow["right"] = obj.right - (grp.right - margin)
            if obj.y < grp.y + margin:
                overflow["top"] = grp.y + margin - obj.y
            if obj.bottom > grp.bottom - margin:
                overflow["bottom"] = obj.bottom - (grp.bottom - margin)

            if overflow:
                issues.append({
                    "obj_id": obj_id,
                    "obj_label": obj.label[:30],
                    "group_id": grp_id,
                    "group_label": grp.label[:30],
                    "overflow": overflow,
                })

    return issues


def fix_group_overflow(path: str, overflow_issues: list[dict], groups: dict[str, Rect]) -> str:
    """グループ枠を拡張してはみ出しを解消する。"""
    tree = ET.parse(path)
    root = tree.getroot()

    expansions: dict[str, dict[str, float]] = {}
    for issue in overflow_issues:
        grp_id = issue["group_id"]
        if grp_id not in expansions:
            expansions[grp_id] = {"left": 0, "right": 0, "top": 0, "bottom": 0}
        for direction, amount in issue["overflow"].items():
            expansions[grp_id][direction] = max(expansions[grp_id][direction], amount + 20)

    for cell in root.iter("mxCell"):
        cell_id = cell.get("id", "")
        if cell_id in expansions:
            geo = cell.find("mxGeometry")
            if geo is not None:
                exp = expansions[cell_id]
                old_x = float(geo.get("x", 0))
                old_y = float(geo.get("y", 0))
                old_w = float(geo.get("width", 0))
                old_h = float(geo.get("height", 0))

                new_x = old_x - exp["left"]
                new_y = old_y - exp["top"]
                new_w = old_w + exp["left"] + exp["right"]
                new_h = old_h + exp["top"] + exp["bottom"]

                geo.set("x", str(new_x))
                geo.set("y", str(new_y))
                geo.set("width", str(new_w))
                geo.set("height", str(new_h))

                grp_label = groups[cell_id].label[:30]
                print(f"    グループ拡張: {grp_label}")
                print(f"      ({old_x:.0f},{old_y:.0f},{old_w:.0f}x{old_h:.0f}) → ({new_x:.0f},{new_y:.0f},{new_w:.0f}x{new_h:.0f})")

    tree.write(path, xml_declaration=True, encoding="unicode")
    return path


def auto_fix(path: str, issues: list[dict], objects: dict[str, Rect], shift_step: float = 60, max_iterations: int = 5) -> str:
    """交差問題を解消するためにオブジェクトをシフトする。"""
    tree = ET.parse(path)
    root = tree.getroot()
    current_objects = copy.deepcopy(objects)

    for iteration in range(max_iterations):
        if not issues:
            break

        print(f"  --- 修正イテレーション {iteration + 1} ---")

        shifts: dict[str, float] = {}
        for issue in issues:
            obj_id = issue["blocked_obj_id"]
            obj = current_objects[obj_id]
            src_x, src_y = issue["src_pos"]
            tgt_x, tgt_y = issue["tgt_pos"]

            line_dx = tgt_x - src_x
            line_dy = tgt_y - src_y
            side = line_dy * (obj.cx - src_x) - line_dx * (obj.cy - src_y)

            if obj_id not in shifts:
                if side >= 0:
                    shifts[obj_id] = shift_step
                else:
                    shifts[obj_id] = -shift_step

        for cell in root.iter("mxCell"):
            cell_id = cell.get("id", "")
            if cell_id in shifts:
                geo = cell.find("mxGeometry")
                if geo is not None:
                    old_x = float(geo.get("x", 0))
                    new_x = old_x + shifts[cell_id]
                    geo.set("x", str(new_x))
                    current_objects[cell_id].x = new_x
                    print(f"    {current_objects[cell_id].label[:20]}... x={old_x:.0f} → {new_x:.0f}")

        _, edges, edge_styles, _ = parse_drawio(path)
        issues = check_overlaps(current_objects, edges, edge_styles)

    out_path = path.replace(".drawio", "_fixed.drawio")
    tree.write(out_path, xml_declaration=True, encoding="unicode")
    return out_path


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "pipeline_flow.drawio"

    print(f"解析中: {path}")
    objects, edges, edge_styles, groups = parse_drawio(path)
    straight_count = sum(1 for e in edges if "orthogonalEdgeStyle" not in edge_styles.get(e.id, ""))
    ortho_count = len(edges) - straight_count
    print(f"  オブジェクト: {len(objects)}個, 矢印: {len(edges)}本 (直線{straight_count}, 折れ線{ortho_count}), グループ: {len(groups)}個")

    has_fix = False

    # 1. 直線矢印の交差チェック
    issues = check_overlaps(objects, edges, edge_styles)
    if issues:
        print(f"\n直線矢印の交差: {len(issues)}件")
        for i, issue in enumerate(issues):
            print(f"  {i+1}. [{issue['source']}] → [{issue['target']}]")
            print(f"     被り: {issue['blocked_by']}")

        print(f"\n自動修正中（矢印交差）...")
        out_path = auto_fix(path, issues, objects)
        has_fix = True

        # 再チェック（2ループ目）
        objects2, edges2, edge_styles2, groups2 = parse_drawio(out_path)
        issues2 = check_overlaps(objects2, edges2, edge_styles2)
        if issues2:
            print(f"  残存する交差: {len(issues2)}件（打ち切り）")
        else:
            print(f"  交差解消。")

        shutil.copy(out_path, path)
        Path(out_path).unlink(missing_ok=True)
    else:
        print("\n直線矢印の交差: なし")

    # 2. グループはみ出しチェック
    objects, edges, edge_styles, groups = parse_drawio(path)
    overflow_issues = check_group_overflow(objects, groups)
    if overflow_issues:
        print(f"\nグループはみ出し: {len(overflow_issues)}件")
        for i, issue in enumerate(overflow_issues):
            dirs = ", ".join(f"{k}:{v:.0f}px" for k, v in issue["overflow"].items())
            print(f"  {i+1}. {issue['obj_label']} → {issue['group_label']} ({dirs})")

        print(f"\n自動修正中（グループ拡張）...")
        fix_group_overflow(path, overflow_issues, groups)
        has_fix = True

        _, _, _, groups2 = parse_drawio(path)
        overflow2 = check_group_overflow(objects, groups2)
        if overflow2:
            print(f"  残存するはみ出し: {len(overflow2)}件（打ち切り）")
        else:
            print(f"  はみ出し解消。")
    else:
        print("グループはみ出し: なし")

    if has_fix:
        print(f"\n修正完了: {path}")
    else:
        print(f"\n問題なし。")

    # _fixedファイルが残っていたら削除
    fixed_path = path.replace(".drawio", "_fixed.drawio")
    Path(fixed_path).unlink(missing_ok=True)


if __name__ == "__main__":
    main()
