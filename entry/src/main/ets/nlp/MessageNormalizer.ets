/**
 * T0 归一化：把 QQ 平台原始文本整理成可读文本。
 *
 * QQ 会把表情下发成 `<faceType=6,faceId="0",ext="eyJ0ZXh0IjoiW+WTh+Whnl0ifQ==">` 这种标记，
 * 其中 ext 是 base64 的 `{"text":"[哇塞]"}`。不归一化的话，界面上就是一片乱码。
 */

import { util } from '@kit.ArkTS';

/** 表情 ext 字段解码后的结构 */
interface FaceExt {
  text?: string;
}

/** 把 `<faceType=...>` 逐个替换成可读表情名（replace 回调在 ArkTS 里不好标注类型，手动扫描） */
function replaceFaces(text: string): string {
  const faceRe = new RegExp('<faceType=(\\d+),faceId="([^"]*)",ext="([^"]*)">', 'g');
  let out: string = '';
  let last: number = 0;
  let m: RegExpExecArray | null = faceRe.exec(text);
  while (m !== null) {
    out += text.substring(last, m.index) + faceLabel(m[3]);
    last = m.index + m[0].length;
    m = faceRe.exec(text);
  }
  out += text.substring(last);
  return out;
}

/** 表情的 ext 是 base64 的 {"text":"[偷笑]"}，解出来更可读；解不出就用 [表情]。 */
function faceLabel(extB64: string): string {
  if (extB64.length === 0) {
    return '[表情]';
  }
  try {
    // 平台有时会省掉结尾的 "="，补足再做 base64 解码
    const pad: number = (4 - (extB64.length % 4)) % 4;
    let b64: string = extB64;
    for (let i = 0; i < pad; i++) {
      b64 += '=';
    }
    const helper = new util.Base64Helper();
    const bytes: Uint8Array = helper.decodeSync(b64);
    const decoder = util.TextDecoder.create('utf-8');
    const jsonStr: string = decoder.decodeToString(bytes);
    const obj = JSON.parse(jsonStr) as FaceExt;
    const label: string = (obj.text ?? '').trim();
    if (label.length === 0) {
      return '[表情]';
    }
    return label.charAt(0) === '[' ? label : '[' + label + ']';
  } catch (e) {
    return '[表情]';
  }
}

/** @ 转文字、表情转可读名、URL 折叠 */
export function normalize(raw: string): string {
  if (raw.length === 0) {
    return '';
  }
  let text: string = raw.replace(/<@!?[0-9A-Za-z]+>/g, '@某人');
  text = replaceFaces(text);
  text = text.replace(/https?:\/\/\S+/g, '[链接]');
  text = text.replace(/[ \t]+/g, ' ');
  return text.trim();
}

/**
 * 判断是否是「不值得整理」的消息——整个链路里最重要的一步过滤。
 * 纯数字、单字符、纯标点、纯表情/@/链接、纯字母缩写都算噪声。
 */
export function isNoise(text: string): boolean {
  const t: string = text.trim();
  if (t.length === 0) {
    return true;
  }
  if (t.length <= 1) {
    return true;
  }
  if (/^[\d\s.,、。!！?？~～-]+$/.test(t)) {
    return true;
  }
  const stripped: string = t.replace(/\[[^\]]*\]|@某人|\[链接\]/g, '').trim();
  if (stripped.length === 0) {
    return true;
  }
  if (/^[A-Za-z]{1,4}$/.test(stripped)) {
    return true;
  }
  return false;
}
