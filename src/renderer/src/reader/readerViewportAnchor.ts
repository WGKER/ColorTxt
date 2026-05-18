import * as monaco from "monaco-editor";
import { physicalLineToFilteredDisplayLine } from "./lineMapping";

/** 切换排版/格式化前后用于恢复视口的锚点（源物理行 + 该行内自动换行视觉行下标） */
export type ReaderViewportRestoreAnchor = {
  physicalLine: number;
  /** 物理行在 Monaco 中折行后的第几条视觉行（0-based） */
  wrappedLineIndex: number;
};

/** 与书签保存一致：视口内容区顶沿往下第 2 条字高带 */
export const READER_VIEWPORT_RESTORE_SLOT_FROM_TOP = 2;

/** 在内容坐标 Y 处命中 Monaco 模型行号（1-based） */
export function findModelLineAtContentY(
  editor: monaco.editor.IStandaloneCodeEditor,
  model: monaco.editor.ITextModel,
  contentY: number,
): number | null {
  const lc = Math.max(1, model.getLineCount());
  let lo = 1;
  let hi = lc;
  let ans = 1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    const top = editor.getTopForLineNumber(mid);
    if (!Number.isFinite(top)) return null;
    if (top <= contentY) {
      ans = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return Math.max(1, Math.min(ans, lc));
}

export function computeWrappedLineIndexInModelLine(
  editor: monaco.editor.IStandaloneCodeEditor,
  displayLine: number,
  contentY: number,
): number {
  const lineHeightPx = Math.max(
    1,
    editor.getOption(monaco.editor.EditorOption.lineHeight),
  );
  const lineTop = editor.getTopForLineNumber(displayLine);
  if (!Number.isFinite(lineTop)) return 0;
  const lineBottom = editor.getBottomForLineNumber(displayLine);
  const blockH = Math.max(0, lineBottom - lineTop);
  const maxIndex = Math.max(0, Math.floor((blockH - 1) / lineHeightPx));
  const idx = Math.floor((contentY - lineTop) / lineHeightPx);
  return Math.max(0, Math.min(idx, maxIndex));
}

export function captureReaderViewportRestoreAnchor(
  editor: monaco.editor.IStandaloneCodeEditor,
  model: monaco.editor.ITextModel,
  resolvePhysicalLine: (displayLine: number) => number,
  anchorSlotFromTop = READER_VIEWPORT_RESTORE_SLOT_FROM_TOP,
): ReaderViewportRestoreAnchor | null {
  editor.layout();
  const lineHeightPx = Math.max(
    1,
    editor.getOption(monaco.editor.EditorOption.lineHeight),
  );
  const scrollTop = Math.max(0, editor.getScrollTop());
  const offsetHeights = Math.max(1, Math.floor(anchorSlotFromTop)) - 1;
  const targetY = scrollTop + offsetHeights * lineHeightPx;
  const displayLine = findModelLineAtContentY(editor, model, targetY);
  if (displayLine == null) return null;
  const physicalLine = Math.max(1, Math.floor(resolvePhysicalLine(displayLine)));
  const wrappedLineIndex = computeWrappedLineIndexInModelLine(
    editor,
    displayLine,
    targetY,
  );
  return { physicalLine, wrappedLineIndex };
}

export function resolveDisplayLineForViewportRestore(
  physicalLine: number,
  modelLineCount: number,
  displayLineToPhysicalLine?: readonly number[],
): number {
  const p = Math.max(1, Math.floor(physicalLine));
  const display =
    displayLineToPhysicalLine && displayLineToPhysicalLine.length > 0
      ? physicalLineToFilteredDisplayLine(p, displayLineToPhysicalLine)
      : p;
  return Math.max(1, Math.min(display, Math.max(1, modelLineCount)));
}

/**
 * 使锚点对应的「物理行 + 折行内行」重新落在视口第 N 条字高带（默认第 2 条）。
 */
export function computeScrollTopForReaderViewportRestoreAnchor(
  editor: monaco.editor.IStandaloneCodeEditor,
  model: monaco.editor.ITextModel,
  anchor: ReaderViewportRestoreAnchor,
  displayLineToPhysicalLine?: readonly number[],
  anchorSlotFromTop = READER_VIEWPORT_RESTORE_SLOT_FROM_TOP,
): number | null {
  editor.layout();
  const lineHeightPx = Math.max(
    1,
    editor.getOption(monaco.editor.EditorOption.lineHeight),
  );
  const displayLine = resolveDisplayLineForViewportRestore(
    anchor.physicalLine,
    model.getLineCount(),
    displayLineToPhysicalLine,
  );
  const lineTop = editor.getTopForLineNumber(displayLine);
  const lineBottom = editor.getBottomForLineNumber(displayLine);
  if (!Number.isFinite(lineTop) || !Number.isFinite(lineBottom)) return null;

  const blockH = Math.max(0, lineBottom - lineTop);
  const maxWrapped = Math.max(0, Math.floor((blockH - 1) / lineHeightPx));
  const wrappedIdx = Math.max(
    0,
    Math.min(Math.floor(anchor.wrappedLineIndex), maxWrapped),
  );
  const pointY = lineTop + wrappedIdx * lineHeightPx;
  const offsetHeights = Math.max(1, Math.floor(anchorSlotFromTop)) - 1;
  const layoutH = Math.max(1, editor.getLayoutInfo().height);
  const maxTop = Math.max(0, editor.getScrollHeight() - layoutH);
  const targetTop = pointY - offsetHeights * lineHeightPx;
  return Math.max(0, Math.min(maxTop, targetTop));
}
