p = r"C:\Users\91224\Desktop\cicad_panel\qqbot-backend\relay.py"
s = open(p, encoding="utf-8").read()
broken = '            "bound_at": b.get("bound_at"),`r`n            "bound_at_ms": b.get("bound_at_ms"),'
fixed = '            "bound_at": b.get("bound_at"),\n            "bound_at_ms": b.get("bound_at_ms"),'
s = s.replace(broken, fixed)

# 管理概览那里缩进不同，单独处理
broken2 = '                        "bound_at": b.get("bound_at"),`r`n            "bound_at_ms": b.get("bound_at_ms"),'
fixed2 = '                        "bound_at": b.get("bound_at"),\n                        "bound_at_ms": b.get("bound_at_ms"),'
s = s.replace(broken2, fixed2)

# bind_by_code 写入数值时间戳
old = '''            self._data["bindings"][device_id] = {
                "user_openid": user_openid,
                "bound_at": _now(),
                "source": source,
            }'''
new = '''            self._data["bindings"][device_id] = {
                "user_openid": user_openid,
                "bound_at": _now(),
                "bound_at_ms": int(time.time() * 1000),
                "source": source,
            }'''
if old in s:
    s = s.replace(old, new)
else:
    print("bind_by_code block not found")

open(p, "w", encoding="utf-8").write(s)
print("fixed")
