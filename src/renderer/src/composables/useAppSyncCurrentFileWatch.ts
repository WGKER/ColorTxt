import { onBeforeUnmount, watch, type Ref } from "vue";
import { fileHistoryKey } from "../stores/recentHistoryStore";

type StreamLike = {
  viewportDisplayLineToPhysicalLine: (displayLine: number) => number;
};

export function useAppSyncCurrentFileWatch(deps: {
  syncCurrentFile: Ref<boolean>;
  physicalReaderPath: Ref<string | null>;
  currentFile: Ref<string | null>;
  loading: Ref<boolean>;
  readingProgressSynced: Ref<boolean>;
  ebookParsing: Ref<boolean>;
  stream: StreamLike;
  viewportEndLine: Ref<number>;
  openFilePath: (
    filePath: string,
    options?: {
      restorePhysicalLine?: number;
      skipRememberCurrent?: boolean;
      keepSidebarTab?: boolean;
    },
  ) => Promise<boolean>;
}) {
  let offDisk: (() => void) | null = null;
  let reloadTimer: ReturnType<typeof setTimeout> | null = null;

  function clearReloadTimer() {
    if (reloadTimer != null) {
      clearTimeout(reloadTimer);
      reloadTimer = null;
    }
  }

  async function invokeWatch(target: string | null) {
    const api = window.colorTxt?.watchCurrentFile;
    if (typeof api !== "function") return;
    try {
      await api(target);
    } catch {
      // ignore
    }
  }

  async function updateWatchFromState() {
    const on =
      deps.syncCurrentFile.value &&
      Boolean(deps.physicalReaderPath.value?.trim()) &&
      !deps.loading.value &&
      !deps.ebookParsing.value &&
      deps.readingProgressSynced.value;
    const p = deps.physicalReaderPath.value?.trim() ?? "";
    await invokeWatch(on && p ? p : null);
  }

  watch(
    [
      () => deps.syncCurrentFile.value,
      () => deps.physicalReaderPath.value,
      () => deps.loading.value,
      () => deps.ebookParsing.value,
      () => deps.readingProgressSynced.value,
    ],
    () => {
      void updateWatchFromState();
    },
    { flush: "post" },
  );

  const sub = window.colorTxt?.onCurrentFileDiskChanged;
  if (typeof sub === "function") {
    offDisk = sub((payload) => {
      const phys = deps.physicalReaderPath.value?.trim();
      if (!phys) return;
      if (fileHistoryKey(payload.path) !== fileHistoryKey(phys)) return;
      if (
        !deps.syncCurrentFile.value ||
        deps.loading.value ||
        deps.ebookParsing.value ||
        !deps.readingProgressSynced.value
      ) {
        return;
      }
      const sessionPath = deps.currentFile.value?.trim();
      if (!sessionPath) return;

      clearReloadTimer();
      reloadTimer = setTimeout(() => {
        reloadTimer = null;
        if (
          !deps.syncCurrentFile.value ||
          deps.loading.value ||
          deps.ebookParsing.value ||
          !deps.readingProgressSynced.value
        ) {
          return;
        }
        const cur = deps.currentFile.value?.trim();
        if (!cur) return;
        const physicalLine = deps.stream.viewportDisplayLineToPhysicalLine(
          deps.viewportEndLine.value,
        );
        void deps.openFilePath(cur, {
          restorePhysicalLine: physicalLine,
          skipRememberCurrent: true,
          keepSidebarTab: true,
        });
      }, 380);
    });
  }

  onBeforeUnmount(() => {
    clearReloadTimer();
    offDisk?.();
    offDisk = null;
    void invokeWatch(null);
  });
}
