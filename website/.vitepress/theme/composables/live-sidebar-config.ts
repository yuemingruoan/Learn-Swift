import { shallowRef } from "vue";
import { sidebarConfig as initialSidebarConfig } from "../../generated/sidebar-data.mjs";

export const liveSidebarConfig = shallowRef(initialSidebarConfig);

if (import.meta.hot) {
  import.meta.hot.accept("../../generated/sidebar-data.mjs", (module) => {
    if (module?.sidebarConfig) {
      liveSidebarConfig.value = module.sidebarConfig;
    }
  });
}
