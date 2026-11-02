# -*- coding: utf-8 -*-
"""核对工作簿的数据、富文本角标与数字格式。"""
from openpyxl import load_workbook
from openpyxl.cell.rich_text import CellRichText

wb = load_workbook("光电效应实验数据表.xlsx", data_only=False, rich_text=True)
ws = wb["光电效应实验数据"]

volt1 = [-2.0, -1.5, -1.0, -0.5, 0, 0.5, 1.0, 1.5, 2.0, 4.0, 6.0, 8.0]
i2_1 = [-0.13, -0.13, -0.11, 0.78, 2.92, 6.89, 10.38, 13.56, 15.91, 27.4, 32.5, 37.0]
i4_1 = [-0.48, -0.43, -0.35, 3.95, 12.10, 26.7, 40.7, 55.0, 62.3, 106.8, 120.8, 144.0]
volt2 = [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0]
i2_2 = [41.0, 44.9, 48.7, 51.3, 53.1, 56.4, 58.0, 61.2, 62.5, 63.0, 65.3, 66.3]
i4_2 = [161.0, 175.7, 186.4, 196.7, 207, 217, 225, 234, 240, 245, 254, 259]

checks = []
checks.append(("U row1", [ws.cell(3, c).value for c in range(2, 14)], volt1))
checks.append(("I d2 row1", [ws.cell(4, c).value for c in range(2, 14)], i2_1))
checks.append(("I d4 row1", [ws.cell(5, c).value for c in range(2, 14)], i4_1))
checks.append(("U row2", [ws.cell(8, c).value for c in range(2, 14)], volt2))
checks.append(("I d2 row2", [ws.cell(9, c).value for c in range(2, 14)], i2_2))
checks.append(("I d4 row2", [ws.cell(10, c).value for c in range(2, 14)], i4_2))
checks.append(("d", [ws.cell(14, c).value for c in (2, 3, 4)], [2, 4, 8]))
checks.append(("d2", [ws.cell(15, c).value for c in (2, 3, 4)], [4, 16, 64]))
checks.append(("IH", [ws.cell(16, c).value for c in (2, 3, 4)], [49.5, 192.7, 774]))
checks.append(("lambda", [ws.cell(19, c).value for c in range(2, 7)], [365, 405, 436, 546, 577]))
checks.append(("nu", [ws.cell(20, c).value for c in range(2, 7)], [8.215, 7.408, 6.879, 5.490, 5.196]))
checks.append(("U0", [ws.cell(21, c).value for c in range(2, 7)], [-1.908, -1.543, -1.325, -0.800, -0.681]))

ok = True
for name, got, want in checks:
    same = len(got) == len(want) and all(abs(a - b) < 1e-9 for a, b in zip(got, want))
    print(("OK  " if same else "FAIL"), name)
    ok &= same

rich_cells = ["A1", "A2", "A3", "A4", "A13", "A14", "A15", "A16", "A18", "A19", "A20", "A21"]
for ref in rich_cells:
    v = ws[ref].value
    print(ref, "rich" if isinstance(v, CellRichText) else type(v).__name__, "|", str(v))

# 角标 run 统计与下划线检查
sub_sup = 0
for row in ws.iter_rows():
    for cell in row:
        v = cell.value
        if isinstance(v, CellRichText):
            for block in v:
                va = getattr(getattr(block, "font", None), "vertAlign", None)
                if va in ("superscript", "subscript"):
                    sub_sup += 1
        if isinstance(v, str) and "_" in v:
            ok = False
            print("UNDERSCORE FOUND:", cell.coordinate, v)
print("角标 run 数:", sub_sup)
print("merged:", [str(r) for r in ws.merged_cells.ranges])
print("formats:", ws["B4"].number_format, ws["B3"].number_format, ws["B16"].number_format,
      ws["B20"].number_format, ws["B21"].number_format)
print("RESULT:", "PASS" if ok and sub_sup >= 8 else "FAIL")
