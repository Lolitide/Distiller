/** 文本小工具（纯函数，供 T1/T2 共用）。 */

/** 字面量替换全部出现（避免动态构造 RegExp 时的转义坑）。 */
export function replaceAllLiteral(s: string, find: string, repl: string): string {
  if (find.length === 0) {
    return s;
  }
  return s.split(find).join(repl);
}

/** 去掉首尾出现在 chars 里的任意字符（等价 Python 的 str.strip(chars)）。 */
export function stripChars(s: string, chars: string): string {
  let start: number = 0;
  let end: number = s.length;
  while (start < end && chars.indexOf(s.charAt(start)) >= 0) {
    start++;
  }
  while (end > start && chars.indexOf(s.charAt(end - 1)) >= 0) {
    end--;
  }
  return s.substring(start, end);
}

/** 文本里是否出现 words 中任意一个。 */
export function anyIn(text: string, words: string[]): boolean {
  for (let i = 0; i < words.length; i++) {
    if (text.indexOf(words[i]) >= 0) {
      return true;
    }
  }
  return false;
}
