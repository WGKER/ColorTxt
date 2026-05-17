import {
  applyLeadIndentFullWidth,
  detectChapterTitle,
} from "../chapter";
import { isBlankPhysicalLineContent } from "./lineMapping";

function normalizeNewlines(text: string): string {
  return text.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

export type CompressBlankFormatResult = {
  text: string;
  /** 显示行号 i（1-based）→ 格式化前源文件物理行号 */
  displayLineToPhysicalLine: number[];
};

/**
 * 与流式读盘「压缩空行」展示逻辑一致，用于编辑模式对 Monaco 全文一次性格式化。
 */
export function formatPlainTextCompressBlankLinesWithMap(
  text: string,
  keepOneBlank: boolean,
): CompressBlankFormatResult {
  const rawLines = normalizeNewlines(text).split("\n");
  const out: string[] = [];
  const displayLineToPhysicalLine: number[] = [];
  const blanksAbove = keepOneBlank ? 1 : 2;
  let physicalLine = 0;

  const pushDisplay = (lineText: string) => {
    displayLineToPhysicalLine.push(physicalLine);
    out.push(lineText);
  };

  for (const rawLine of rawLines) {
    physicalLine += 1;
    if (isBlankPhysicalLineContent(rawLine)) continue;
    const title = detectChapterTitle(rawLine);
    if (title) {
      for (let i = 0; i < blanksAbove; i += 1) pushDisplay("");
      pushDisplay(rawLine);
      pushDisplay("");
      continue;
    }
    pushDisplay(rawLine);
    if (keepOneBlank) pushDisplay("");
  }

  return { text: out.join("\n"), displayLineToPhysicalLine };
}

export function formatPlainTextCompressBlankLines(
  text: string,
  keepOneBlank: boolean,
): string {
  return formatPlainTextCompressBlankLinesWithMap(text, keepOneBlank).text;
}

/** 对全文逐行应用行首全角缩进（章节标题与空行除外） */
export function formatPlainTextLeadIndentFullWidth(text: string): string {
  const lines = normalizeNewlines(text).split("\n");
  return lines.map((line) => applyLeadIndentFullWidth(line)).join("\n");
}
