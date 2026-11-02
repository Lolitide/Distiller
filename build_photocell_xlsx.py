# -*- coding: utf-8 -*-
"""生成光电效应实验数据表（三张表，同一工作表内分隔排布，角标用上下标格式）。"""
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.styles.colors import Color
from openpyxl.cell.rich_text import CellRichText, TextBlock
from openpyxl.cell.text import InlineFont
from openpyxl.worksheet.properties import PageSetupProperties

OUT = "光电效应实验数据表.xlsx"
FONT = "宋体"

THIN = Border(
    left=Side(style="thin", color="FF404040"),
    right=Side(style="thin", color="FF404040"),
    top=Side(style="thin", color="FF404040"),
    bottom=Side(style="thin", color="FF404040"),
)
TITLE_FILL = PatternFill("solid", fgColor="FFDCE6F1")
HEAD_FILL = PatternFill("solid", fgColor="FFD9E2F3")
LABEL_FILL = PatternFill("solid", fgColor="FFF2F2F2")


def run(text, b=True, i=False, sz=11, color="FF1F1F1F", va=None):
    return TextBlock(
        InlineFont(rFont=FONT, sz=sz, b=b, i=i, color=Color(rgb=color), vertAlign=va),
        text,
    )


def rich(*parts):
    return CellRichText(list(parts))


def title_block(ws, row, last_col, parts):
    for c in range(1, last_col + 1):
        cell = ws.cell(row=row, column=c)
        cell.fill = TITLE_FILL
        cell.border = Border(bottom=Side(style="medium", color="FF8EA9DB"))
    ws.merge_cells(start_row=row, start_column=1, end_row=row, end_column=last_col)
    cell = ws.cell(row=row, column=1)
    cell.value = rich(*parts)
    cell.alignment = Alignment(horizontal="center", vertical="center")


def label_cell(ws, row, col, parts, fill=LABEL_FILL):
    cell = ws.cell(row=row, column=col)
    cell.value = rich(*parts)
    cell.fill = fill
    cell.border = THIN
    cell.alignment = Alignment(horizontal="left", vertical="center", indent=1)


def head_cell(ws, row, col, value=None, fmt=None):
    cell = ws.cell(row=row, column=col)
    if value is not None:
        cell.value = value
    cell.fill = HEAD_FILL
    cell.border = THIN
    cell.font = Font(name=FONT, size=11, bold=True)
    cell.alignment = Alignment(horizontal="center", vertical="center")
    if fmt:
        cell.number_format = fmt


def data_cell(ws, row, col, value, fmt):
    cell = ws.cell(row=row, column=col, value=value)
    cell.border = THIN
    cell.font = Font(name=FONT, size=11)
    cell.alignment = Alignment(horizontal="center", vertical="center")
    cell.number_format = fmt


# ------------------------------------------------------------------ 数据
volt1 = [-2.0, -1.5, -1.0, -0.5, 0, 0.5, 1.0, 1.5, 2.0, 4.0, 6.0, 8.0]
i2_1 = [-0.13, -0.13, -0.11, 0.78, 2.92, 6.89, 10.38, 13.56, 15.91, 27.4, 32.5, 37.0]
i4_1 = [-0.48, -0.43, -0.35, 3.95, 12.10, 26.7, 40.7, 55.0, 62.3, 106.8, 120.8, 144.0]

volt2 = [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0]
i2_2 = [41.0, 44.9, 48.7, 51.3, 53.1, 56.4, 58.0, 61.2, 62.5, 63.0, 65.3, 66.3]
i4_2 = [161.0, 175.7, 186.4, 196.7, 207, 217, 225, 234, 240, 245, 254, 259]

d_vals = [2, 4, 8]
d2_vals = [4, 16, 64]
ih_vals = [49.5, 192.7, 774]

lam = [365, 405, 436, 546, 577]
nu = [8.215, 7.408, 6.879, 5.490, 5.196]
u0 = [-1.908, -1.543, -1.325, -0.800, -0.681]

wb = Workbook()
ws = wb.active
ws.title = "光电效应实验数据"
ws.sheet_view.showGridLines = False

ws.column_dimensions["A"].width = 22.5
for col in "BCDEFGHIJKLM":
    ws.column_dimensions[col].width = 8.4

# ------------------------------------------------------------------ 表1
title_block(ws, 1, 13, [
    run("表1　光电管 ", b=True, sz=13, color="FF1F3864"),
    run("I", b=True, i=True, sz=13, color="FF1F3864"),
    run("–", b=True, sz=13, color="FF1F3864"),
    run("U", b=True, i=True, sz=13, color="FF1F3864"),
    run(" 特性曲线（", b=True, sz=13, color="FF1F3864"),
    run("λ", b=True, i=True, sz=13, color="FF1F3864"),
    run(" = 546 nm）", b=True, sz=13, color="FF1F3864"),
])

note = ws.cell(row=2, column=1)
note.value = rich(
    run("电流 ", b=False, sz=9, color="FF595959"),
    run("I", b=False, i=True, sz=9, color="FF595959"),
    run(" 的单位：×10", b=False, sz=9, color="FF595959"),
    run("-11", b=False, sz=9, color="FF595959", va="superscript"),
    run(" A；", b=False, sz=9, color="FF595959"),
    run("d", b=False, i=True, sz=9, color="FF595959"),
    run(" 为光阑孔直径", b=False, sz=9, color="FF595959"),
)
note.alignment = Alignment(horizontal="left", vertical="center", indent=1)

head_cell(ws, 3, 1)
ws.cell(row=3, column=1).value = rich(run("U", i=True), run(" (V)"))
for idx, v in enumerate(volt1):
    head_cell(ws, 3, 2 + idx, v, "0.0")

label_cell(ws, 4, 1, [run("d", i=True), run(" = 2 mm")])
for idx, v in enumerate(i2_1):
    data_cell(ws, 4, 2 + idx, v, "0.0#")

label_cell(ws, 5, 1, [run("d", i=True), run(" = 4 mm")])
for idx, v in enumerate(i4_1):
    data_cell(ws, 5, 2 + idx, v, "0.0#")

cont = ws.cell(row=7, column=1)
cont.value = rich(run("（续表）", b=True, i=False, sz=9, color="FF595959"))
cont.alignment = Alignment(horizontal="left", vertical="center", indent=1)

head_cell(ws, 8, 1)
ws.cell(row=8, column=1).value = rich(run("U", i=True), run(" (V)"))
for idx, v in enumerate(volt2):
    head_cell(ws, 8, 2 + idx, v, "0.0")

label_cell(ws, 9, 1, [run("d", i=True), run(" = 2 mm")])
for idx, v in enumerate(i2_2):
    data_cell(ws, 9, 2 + idx, v, "0.0#")

label_cell(ws, 10, 1, [run("d", i=True), run(" = 4 mm")])
for idx, v in enumerate(i4_2):
    data_cell(ws, 10, 2 + idx, v, "0.0#")

# ------------------------------------------------------------------ 表2
title_block(ws, 13, 13, [
    run("表2　光电管光电特性（", sz=13, color="FF1F3864"),
    run("λ", i=True, sz=13, color="FF1F3864"),
    run(" = 577 nm，", sz=13, color="FF1F3864"),
    run("U", i=True, sz=13, color="FF1F3864"),
    run("a", i=True, sz=13, color="FF1F3864", va="subscript"),
    run(" = 25 V）", sz=13, color="FF1F3864"),
])

label_cell(ws, 14, 1, [run("光阑孔 "), run("d", i=True), run(" (mm)")])
head_cell(ws, 14, 2)
head_cell(ws, 14, 3)
head_cell(ws, 14, 4)
for idx, v in enumerate(d_vals):
    head_cell(ws, 14, 2 + idx, v, "0")

label_cell(ws, 15, 1, [
    run("d", i=True),
    run("2", va="superscript"),
    run(" (mm"),
    run("2", va="superscript"),
    run(")"),
])
for idx, v in enumerate(d2_vals):
    data_cell(ws, 15, 2 + idx, v, "0")

label_cell(ws, 16, 1, [
    run("I", i=True),
    run("H", i=True, va="subscript"),
    run(" (×10"),
    run("-11", va="superscript"),
    run(" A)"),
])
for idx, v in enumerate(ih_vals):
    data_cell(ws, 16, 2 + idx, v, "0.0#")

# ------------------------------------------------------------------ 表3
title_block(ws, 18, 13, [
    run("表3　普朗克常量测定（量程 ×10", sz=13, color="FF1F3864"),
    run("-13", sz=13, color="FF1F3864", va="superscript"),
    run(" A，", sz=13, color="FF1F3864"),
    run("d", i=True, sz=13, color="FF1F3864"),
    run(" = 4 mm）", sz=13, color="FF1F3864"),
])

label_cell(ws, 19, 1, [run("波长 "), run("λ", i=True), run(" (nm)")])
for idx, v in enumerate(lam):
    head_cell(ws, 19, 2 + idx, v, "0")

label_cell(ws, 20, 1, [
    run("频率 "),
    run("ν", i=True),
    run(" (×10"),
    run("14", va="superscript"),
    run(" Hz)"),
])
for idx, v in enumerate(nu):
    data_cell(ws, 20, 2 + idx, v, "0.000")

label_cell(ws, 21, 1, [
    run("遏止电压 "),
    run("U", i=True),
    run("0", i=True, va="subscript"),
    run(" (V)"),
])
for idx, v in enumerate(u0):
    data_cell(ws, 21, 2 + idx, v, "0.000")

# ------------------------------------------------------------------ 版面
heights = {1: 30, 2: 18, 3: 26, 4: 22, 5: 22, 6: 10, 7: 20, 8: 26, 9: 22,
           10: 22, 11: 12, 12: 12, 13: 30, 14: 26, 15: 22, 16: 22,
           17: 12, 18: 30, 19: 26, 20: 22, 21: 22}
for r, h in heights.items():
    ws.row_dimensions[r].height = h

ws.page_setup.orientation = "landscape"
ws.page_setup.paperSize = ws.PAPERSIZE_A4
ws.sheet_properties.pageSetUpPr = PageSetupProperties(fitToPage=True)
ws.page_setup.fitToWidth = 1
ws.page_setup.fitToHeight = 0
ws.print_options.horizontalCentered = True
ws.page_margins.left = 0.5
ws.page_margins.right = 0.5
ws.page_margins.top = 0.6
ws.page_margins.bottom = 0.6

wb.properties.title = "光电效应实验数据表"
wb.properties.subject = "光电管 I-U 特性、光电特性、普朗克常量测定"

wb.save(OUT)
print("saved", OUT)
