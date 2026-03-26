import { isActive } from "vitepress/dist/client/shared.js";

function ensureStartingSlash(path: string) {
  return /^\//.test(path) ? path : `/${path}`;
}

export function getSidebar(_sidebar: any, path: string) {
  if (Array.isArray(_sidebar)) {
    return addBase(_sidebar);
  }

  if (_sidebar == null) {
    return [];
  }

  path = ensureStartingSlash(path);

  const dir = Object.keys(_sidebar)
    .sort((a, b) => b.split("/").length - a.split("/").length)
    .find((dir) => path.startsWith(ensureStartingSlash(dir)));

  const sidebar = dir ? _sidebar[dir] : [];

  return Array.isArray(sidebar)
    ? addBase(sidebar)
    : addBase(sidebar.items, sidebar.base);
}

export function getSidebarGroups(sidebar: any[]) {
  const groups = [];
  let lastGroupIndex = 0;

  for (const index in sidebar) {
    const item = sidebar[index];

    if (item.items) {
      lastGroupIndex = groups.push(item);
      continue;
    }

    if (!groups[lastGroupIndex]) {
      groups.push({ items: [] });
    }

    groups[lastGroupIndex].items.push(item);
  }

  return groups;
}

export function getFlatSideBarLinks(sidebar: any[]) {
  const links: any[] = [];

  function recursivelyExtractLinks(items: any[]) {
    for (const item of items) {
      if (item.text && item.link) {
        links.push({
          text: item.text,
          link: item.link,
          docFooterText: item.docFooterText,
        });
      }

      if (item.items) {
        recursivelyExtractLinks(item.items);
      }
    }
  }

  recursivelyExtractLinks(sidebar);

  return links;
}

export function hasActiveLink(path: string, items: any): boolean {
  if (Array.isArray(items)) {
    return items.some((item) => hasActiveLink(path, item));
  }

  return isActive(path, items.link)
    ? true
    : items.items
      ? hasActiveLink(path, items.items)
      : false;
}

function addBase(items: any[], _base?: string) {
  return [...items].map((_item) => {
    const item = { ..._item };
    const base = item.base || _base;

    if (base && item.link) {
      item.link = base + item.link;
    }

    if (item.items) {
      item.items = addBase(item.items, base);
    }

    return item;
  });
}
