<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";

type ContextMenuItem = {
  id: string;
  label?: string;
  type?: "primary" | "success" | "warning" | "danger";
  separator?: boolean;
};

const props = defineProps<{
  open: boolean;
  x: number;
  y: number;
  items: readonly ContextMenuItem[];
  minWidth?: number;
}>();

const emit = defineEmits<{
  close: [];
  select: [id: string];
}>();

const menuRef = ref<HTMLElement | null>(null);
const posX = ref(0);
const posY = ref(0);

function itemClass(item: ContextMenuItem) {
  const c = ["appShellMenuItem"];
  if (item.type) c.push(`appShellMenuItem--${item.type}`);
  return c.join(" ");
}

function clampPosition() {
  const menu = menuRef.value;
  if (!menu) return;
  const margin = 8;
  const maxX = Math.max(margin, window.innerWidth - menu.offsetWidth - margin);
  const maxY = Math.max(
    margin,
    window.innerHeight - menu.offsetHeight - margin,
  );
  posX.value = Math.min(Math.max(margin, props.x), maxX);
  posY.value = Math.min(Math.max(margin, props.y), maxY);
}

watch(
  () => props.open,
  async (open) => {
    if (!open) return;
    posX.value = props.x;
    posY.value = props.y;
    await nextTick();
    clampPosition();
  },
);

watch(
  () => [props.x, props.y] as const,
  () => {
    if (!props.open) return;
    posX.value = props.x;
    posY.value = props.y;
    void nextTick().then(clampPosition);
  },
);

function onDocPointerDown(ev: PointerEvent) {
  if (!props.open) return;
  const t = ev.target as Node | null;
  if (t && menuRef.value?.contains(t)) return;
  emit("close");
}

function onWindowInvalidate() {
  if (!props.open) return;
  emit("close");
}

onMounted(() => {
  document.addEventListener("pointerdown", onDocPointerDown);
  window.addEventListener("resize", onWindowInvalidate);
  window.addEventListener("blur", onWindowInvalidate);
});

onBeforeUnmount(() => {
  document.removeEventListener("pointerdown", onDocPointerDown);
  window.removeEventListener("resize", onWindowInvalidate);
  window.removeEventListener("blur", onWindowInvalidate);
});
</script>

<template>
  <div
    v-if="open"
    ref="menuRef"
    class="contextMenu appShellMenuPanel"
    role="menu"
    :style="{
      left: `${posX}px`,
      top: `${posY}px`,
      minWidth: `${minWidth ?? 140}px`,
    }"
    @click.stop
  >
    <template v-for="item in items" :key="item.id">
      <div
        v-if="item.separator"
        class="appShellMenuDivider"
        role="separator"
      />
      <button
        v-else
        type="button"
        :class="itemClass(item)"
        role="menuitem"
        @click="emit('select', item.id)"
      >
        {{ item.label }}
      </button>
    </template>
  </div>
</template>

<style scoped>
.contextMenu {
  position: fixed;
  z-index: 7000;
}
</style>
