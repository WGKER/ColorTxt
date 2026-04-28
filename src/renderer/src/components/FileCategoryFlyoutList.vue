<script setup lang="ts">
import type { FileCategoryDefinition } from "../constants/fileCategories";

defineProps<{
  catalog: FileCategoryDefinition[];
  menuCounts: {
    uncategorized: number;
    byName: Record<string, number>;
  };
}>();

const emit = defineEmits<{
  pick: [name: string];
}>();
</script>

<template>
  <div class="appShellMenuFlyoutList">
    <button
      type="button"
      class="appShellMenuFlyoutItem"
      role="menuitem"
      @click="emit('pick', '')"
    >
      <span class="appShellMenuItemRowBody">
        <span class="appShellMenuItemLabelWithCount">
          <span class="appShellMenuItemLabelText">未分类</span>
          <span class="appShellMenuItemSuffix">({{ menuCounts.uncategorized }})</span>
        </span>
      </span>
    </button>
    <div class="appShellMenuFlyoutDivider" role="separator" />
    <button
      v-for="(c, i) in catalog"
      :key="i"
      type="button"
      class="appShellMenuFlyoutItem"
      role="menuitem"
      @click="emit('pick', c.name)"
    >
      <span
        class="appShellMenuItemMark"
        aria-hidden="true"
        :style="{ backgroundColor: c.color }"
      />
      <span class="appShellMenuItemRowBody">
        <span class="appShellMenuItemLabelWithCount">
          <span class="appShellMenuItemLabelText">{{ c.name }}</span>
          <span class="appShellMenuItemSuffix"
            >({{ menuCounts.byName[c.name] ?? 0 }})</span
          >
        </span>
      </span>
    </button>
  </div>
</template>

